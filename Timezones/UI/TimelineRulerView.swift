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
    let soundEffectsEnabled: Bool
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
                    soundEffectsEnabled: soundEffectsEnabled,
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
    let soundEffectsEnabled: Bool
    let onOffsetChange: @MainActor (TimeInterval) -> Void
    let onInteractionEnded: @MainActor () -> Void

    func makeNSView(context: Context) -> TimelineRulerNSView {
        let view = TimelineRulerNSView()
        view.timelineOffset = timelineOffset
        view.apply(colorScheme: colorScheme)
        view.soundEffectsEnabled = soundEffectsEnabled
        view.onOffsetChange = onOffsetChange
        view.onInteractionEnded = onInteractionEnded
        return view
    }

    func updateNSView(_ nsView: TimelineRulerNSView, context: Context) {
        nsView.timelineOffset = timelineOffset
        nsView.apply(colorScheme: colorScheme)
        nsView.soundEffectsEnabled = soundEffectsEnabled
        nsView.onOffsetChange = onOffsetChange
        nsView.onInteractionEnded = onInteractionEnded
        nsView.needsDisplay = true
    }
}

@MainActor
private final class TimelineRulerNSView: NSView {
    var timelineOffset: TimeInterval = 0
    var soundEffectsEnabled = true
    var onOffsetChange: (@MainActor (TimeInterval) -> Void)?
    var onInteractionEnded: (@MainActor () -> Void)?

    private var dragStartLocation: NSPoint?
    private var dragStartOffset: TimeInterval = 0
    private var lastFeedbackStep: Int?
    private lazy var detentSound = TimelineDetentSound()

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
        if soundEffectsEnabled, let lastFeedbackStep, step != lastFeedbackStep {
            detentSound.play()
        }
        lastFeedbackStep = step
        onOffsetChange?(proposedOffset)
    }

    private func feedbackStep(for offset: TimeInterval) -> Int {
        Int((offset / AppModel.snappingInterval).rounded(.towardZero))
    }
}

@MainActor
private final class TimelineDetentSound {
    private static let sampleRate = 44_100
    private static let duration: TimeInterval = 0.018
    private static let voiceCount = 4

    private let voices: [NSSound]
    private var nextVoice = 0

    init() {
        let soundData = Self.makeWaveData()
        voices = (0..<Self.voiceCount).compactMap { _ in
            guard let sound = NSSound(data: soundData) else { return nil }
            sound.volume = 0.14
            return sound
        }
    }

    func play() {
        guard !voices.isEmpty else { return }

        let voice = voices[nextVoice]
        nextVoice = (nextVoice + 1) % voices.count
        voice.stop()
        voice.currentTime = 0
        voice.play()
    }

    private static func makeWaveData() -> Data {
        let frameCount = Int(Double(sampleRate) * duration)
        var pcmData = Data(capacity: frameCount * MemoryLayout<Int16>.size)
        var randomState: UInt32 = 0xA11D1A1
        var previousNoise = 0.0

        for frame in 0..<frameCount {
            let time = Double(frame) / Double(sampleRate)
            let attack = min(time / 0.00032, 1)

            randomState = 1_664_525 &* randomState &+ 1_013_904_223
            let noise = Double(Int32(bitPattern: randomState)) / Double(Int32.max)
            let highPassedNoise = noise - previousNoise * 0.82
            previousNoise = noise

            let snap = sin(2 * .pi * 3_250 * time) * exp(-time * 520) * 0.30
            let mechanism = sin(2 * .pi * 1_050 * time + 0.35) * exp(-time * 310) * 0.09
            let body = sin(2 * .pi * 260 * time) * exp(-time * 165) * 0.05
            let texture = highPassedNoise * exp(-time * 680) * 0.025

            let reboundTime = time - 0.0018
            let rebound = reboundTime > 0
                ? sin(2 * .pi * 2_300 * reboundTime) * exp(-reboundTime * 650) * 0.045
                : 0

            let mixed = attack * (snap + mechanism + body + texture + rebound)
            let shaped = tanh(mixed * 1.05) * 0.56
            let sample = Int16(
                max(-1, min(1, shaped)) * Double(Int16.max)
            )
            pcmData.appendLittleEndian(sample)
        }

        var waveData = Data(capacity: 44 + pcmData.count)
        waveData.append(contentsOf: "RIFF".utf8)
        waveData.appendLittleEndian(UInt32(36 + pcmData.count))
        waveData.append(contentsOf: "WAVE".utf8)
        waveData.append(contentsOf: "fmt ".utf8)
        waveData.appendLittleEndian(UInt32(16))
        waveData.appendLittleEndian(UInt16(1))
        waveData.appendLittleEndian(UInt16(1))
        waveData.appendLittleEndian(UInt32(sampleRate))
        waveData.appendLittleEndian(UInt32(sampleRate * MemoryLayout<Int16>.size))
        waveData.appendLittleEndian(UInt16(MemoryLayout<Int16>.size))
        waveData.appendLittleEndian(UInt16(16))
        waveData.append(contentsOf: "data".utf8)
        waveData.appendLittleEndian(UInt32(pcmData.count))
        waveData.append(pcmData)
        return waveData
    }
}

private extension Data {
    mutating func appendLittleEndian<Value: FixedWidthInteger>(_ value: Value) {
        var littleEndianValue = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndianValue) { bytes in
            append(contentsOf: bytes)
        }
    }
}
