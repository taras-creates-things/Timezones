import AppKit
import SwiftUI

private enum TimelineRulerMetrics {
    static let pointsPerHour: CGFloat = 48
    static let secondsPerPoint = TimeInterval(60 * 60) / TimeInterval(pointsPerHour)
    static let minorTickInterval: TimeInterval = 5 * 60
    static let tickSpacing = pointsPerHour / 12
    static let headerHeight: CGFloat = 36
    static let rulerHeight: CGFloat = 50
    static let selectedMarkerHeight: CGFloat = 31
}

struct TimelineRulerView: View {
    @Environment(\.colorScheme) private var colorScheme

    let selectedDate: Date
    let homeTimeZone: TimeZone
    let timelineOffset: TimeInterval
    let onOffsetChange: @MainActor (TimeInterval) -> Void
    let onInteractionEnded: @MainActor () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            TimelineSelectionRange(timelineOffset: timelineOffset)

            VStack(spacing: 0) {
                HStack {
                    Text(TimeEngine.utcOffsetString(for: selectedDate, in: homeTimeZone))
                    Spacer()
                    Text(TimeEngine.timelineOffsetString(timelineOffset))
                        .contentTransition(.numericText())
                        .animation(.easeOut(duration: 0.16), value: timelineOffset)
                }
                .font(AppTypography.secondary(size: 10, relativeTo: .caption2))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .padding(.horizontal, DesignTokens.cellInset)
                .frame(height: TimelineRulerMetrics.headerHeight)

                RulerInteractionView(
                    timelineOffset: timelineOffset,
                    colorScheme: colorScheme,
                    onOffsetChange: onOffsetChange,
                    onInteractionEnded: onInteractionEnded
                )
                .frame(height: TimelineRulerMetrics.rulerHeight)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Time ruler")
                .accessibilityValue(TimeEngine.timelineOffsetString(timelineOffset))
                .accessibilityHint("Drag or scroll horizontally to compare another time")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment:
                        onOffsetChange(timelineOffset + AppModel.snappingInterval)
                        onInteractionEnded()
                    case .decrement:
                        onOffsetChange(timelineOffset - AppModel.snappingInterval)
                        onInteractionEnded()
                    @unknown default:
                        break
                    }
                }
            }
        }
        .frame(height: DesignTokens.rulerHeight)
    }
}

private struct TimelineSelectionRange: View {
    @Environment(\.colorScheme) private var colorScheme
    let timelineOffset: TimeInterval

    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let nowX = centerX - CGFloat(timelineOffset / TimelineRulerMetrics.secondsPerPoint)
            let clampedNowX = min(max(nowX, 0), geometry.size.width)
            let rangeStart = min(centerX, clampedNowX)
            let rangeWidth = abs(centerX - clampedNowX)

            if abs(timelineOffset) > TimelineRulerMetrics.secondsPerPoint / 2 {
                Rectangle()
                    .fill(Color("AccentColor"))
                    .opacity(colorScheme == .dark ? 0.28 : 0.12)
                    .frame(width: rangeWidth, height: geometry.size.height)
                    .offset(x: rangeStart)
            }

            Rectangle()
                .fill(Color("AccentColor"))
                .frame(width: 2, height: TimelineRulerMetrics.selectedMarkerHeight)
                .offset(x: centerX - 1)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

@MainActor
private struct RulerInteractionView: NSViewRepresentable {
    let timelineOffset: TimeInterval
    let colorScheme: ColorScheme
    let onOffsetChange: @MainActor (TimeInterval) -> Void
    let onInteractionEnded: @MainActor () -> Void

    func makeNSView(context: Context) -> TimelineRulerNSView {
        let view = TimelineRulerNSView()
        view.timelineOffset = timelineOffset
        view.apply(colorScheme: colorScheme)
        view.onOffsetChange = onOffsetChange
        view.onInteractionEnded = onInteractionEnded
        return view
    }

    func updateNSView(_ nsView: TimelineRulerNSView, context: Context) {
        nsView.timelineOffset = timelineOffset
        nsView.apply(colorScheme: colorScheme)
        nsView.onOffsetChange = onOffsetChange
        nsView.onInteractionEnded = onInteractionEnded
        nsView.needsDisplay = true
    }
}

@MainActor
private final class TimelineRulerNSView: NSView {
    var timelineOffset: TimeInterval = 0
    var onOffsetChange: (@MainActor (TimeInterval) -> Void)?
    var onInteractionEnded: (@MainActor () -> Void)?

    private var dragStartLocation: NSPoint?
    private var dragStartOffset: TimeInterval = 0
    private var lastFeedbackStep: Int?
    private lazy var tickSound: NSSound? = {
        let sound = NSSound(named: NSSound.Name("Tink"))
        sound?.volume = 0.22
        return sound
    }()

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setAccessibilityElement(false)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setAccessibilityElement(false)
    }

    func apply(colorScheme: ColorScheme) {
        let name: NSAppearance.Name = colorScheme == .dark ? .darkAqua : .aqua
        if appearance?.name != name {
            appearance = NSAppearance(named: name)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let centerX = bounds.midX
        let selectedTick = timelineOffset / TimelineRulerMetrics.minorTickInterval
        let baseTick = floor(selectedTick)
        let fractionalTick = selectedTick - baseTick
        let visibleTickCount = Int(ceil(bounds.width / TimelineRulerMetrics.tickSpacing)) + 4
        let nowX = centerX - CGFloat(timelineOffset / TimelineRulerMetrics.secondsPerPoint)
        let selectedRange = min(centerX, nowX)...max(centerX, nowX)
        let hasSelectedRange = abs(timelineOffset) > TimelineRulerMetrics.secondsPerPoint / 2
        let orange = NSColor(red: 1, green: 0.478, blue: 0.102, alpha: 1)

        for relativeTick in (-visibleTickCount)...visibleTickCount {
            let x = centerX
                + (CGFloat(relativeTick) - CGFloat(fractionalTick))
                * TimelineRulerMetrics.tickSpacing
            guard x >= bounds.minX - TimelineRulerMetrics.tickSpacing,
                  x <= bounds.maxX + TimelineRulerMetrics.tickSpacing else { continue }

            let absoluteTick = Int(baseTick) + relativeTick
            let isHour = absoluteTick.isMultiple(of: 12)
            let isHalfHour = absoluteTick.isMultiple(of: 6)
            let isQuarterHour = absoluteTick.isMultiple(of: 3)
            let tickHeight: CGFloat = isHour ? 31 : (isHalfHour ? 25 : (isQuarterHour ? 21 : 16))

            let path = NSBezierPath()
            path.move(to: NSPoint(x: x.rounded() + 0.5, y: bounds.maxY))
            path.line(to: NSPoint(x: x.rounded() + 0.5, y: bounds.maxY - tickHeight))
            path.lineWidth = 1
            if hasSelectedRange && selectedRange.contains(x) {
                orange.setStroke()
            } else {
                NSColor.labelColor.withAlphaComponent(0.34).setStroke()
            }
            path.stroke()
        }
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        dragStartLocation = convert(event.locationInWindow, from: nil)
        dragStartOffset = timelineOffset
        lastFeedbackStep = feedbackStep(for: timelineOffset)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let dragStartLocation else { return }
        let currentLocation = convert(event.locationInWindow, from: nil)
        let translation = currentLocation.x - dragStartLocation.x
        updateTimeline(
            to: dragStartOffset
                - TimeInterval(translation) * TimelineRulerMetrics.secondsPerPoint
        )
    }

    override func mouseUp(with event: NSEvent) {
        dragStartLocation = nil
        lastFeedbackStep = nil
        onInteractionEnded?()
    }

    override func scrollWheel(with event: NSEvent) {
        guard abs(event.scrollingDeltaX) > 0.01 else {
            super.scrollWheel(with: event)
            return
        }

        if lastFeedbackStep == nil {
            lastFeedbackStep = feedbackStep(for: timelineOffset)
        }
        updateTimeline(
            to: timelineOffset
                + TimeInterval(event.scrollingDeltaX) * TimelineRulerMetrics.secondsPerPoint
        )

        let hasNoPhases = event.phase.isEmpty && event.momentumPhase.isEmpty
        if hasNoPhases || event.phase == .ended || event.momentumPhase == .ended {
            lastFeedbackStep = nil
            onInteractionEnded?()
        }
    }

    override func keyDown(with event: NSEvent) {
        let step: TimeInterval = event.modifierFlags.contains(.shift) ? 60 * 60 : AppModel.snappingInterval
        switch event.keyCode {
        case 123:
            lastFeedbackStep = feedbackStep(for: timelineOffset)
            updateTimeline(to: timelineOffset - step)
            lastFeedbackStep = nil
            onInteractionEnded?()
        case 124:
            lastFeedbackStep = feedbackStep(for: timelineOffset)
            updateTimeline(to: timelineOffset + step)
            lastFeedbackStep = nil
            onInteractionEnded?()
        default:
            super.keyDown(with: event)
        }
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .resizeLeftRight)
    }

    private func updateTimeline(to proposedOffset: TimeInterval) {
        let step = feedbackStep(for: proposedOffset)
        if let lastFeedbackStep, step != lastFeedbackStep {
            tickSound?.stop()
            tickSound?.play()
        }
        lastFeedbackStep = step
        onOffsetChange?(proposedOffset)
    }

    private func feedbackStep(for offset: TimeInterval) -> Int {
        Int((offset / AppModel.snappingInterval).rounded(.towardZero))
    }
}
