import AppKit
import QuartzCore
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    private enum Metrics {
        static let panelGap: CGFloat = 4
        static let screenInset: CGFloat = 8
        static let initialPanelHeight: CGFloat = 405
        static let presentationScale: CGFloat = 0.97
        static let presentationDuration: TimeInterval = 0.18
    }

    private let model = AppModel()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let panel = StatusPanel(
        contentRect: NSRect(
            x: 0,
            y: 0,
            width: DesignTokens.panelWidth,
            height: Metrics.initialPanelHeight
        ),
        styleMask: [.borderless],
        backing: .buffered,
        defer: true
    )

    private var hostingController: NSHostingController<StatusPanelRoot>?
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?
    private var presentationGeneration = 0
    private var isClosing = false

    override init() {
        super.init()
        configureStatusItem()
        configurePanel()
        installDismissalMonitors()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        let image = NSImage(named: "MenuBarIcon")
        image?.accessibilityDescription = "Timezones"
        image?.isTemplate = true
        image?.size = NSSize(width: 18, height: 18)
        button.image = image
        button.imagePosition = .imageOnly
        button.toolTip = "Timezones"
        button.target = self
        button.action = #selector(togglePanel)
        button.sendAction(on: [.leftMouseDown])
    }

    private func configurePanel() {
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.sharingType = .readOnly
        panel.isReleasedWhenClosed = false
        panel.level = .popUpMenu
        panel.collectionBehavior = [.transient, .moveToActiveSpace, .fullScreenAuxiliary]
        panel.animationBehavior = .utilityWindow
        panel.alphaValue = 1

        let root = StatusPanelRoot(model: model) { [weak self] size in
            self?.updatePanelSize(size)
        }
        let hostingController = NSHostingController(rootView: root)
        hostingController.view.wantsLayer = true
        self.hostingController = hostingController
        panel.contentViewController = hostingController
    }

    private func installDismissalMonitors() {
        localEventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .keyDown]
        ) { [weak self] event in
            guard let self, self.panel.isVisible else { return event }

            if event.type == .keyDown, event.keyCode == 53 {
                self.closePanel()
                return nil
            }

            let statusBarWindow = self.statusItem.button?.window
            if event.window !== self.panel, event.window !== statusBarWindow {
                self.closePanel()
            }
            return event
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            Task { @MainActor in
                self?.closePanel()
            }
        }
    }

    @objc private func togglePanel() {
        if isClosing {
            openPanel()
        } else if panel.isVisible {
            closePanel()
        } else {
            openPanel()
        }
    }

    private func openPanel() {
        presentationGeneration += 1
        isClosing = false
        resetPresentationLayer()
        positionPanel()
        statusItem.button?.highlight(true)
        NSApplication.shared.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        animatePanelOpening()
    }

    private func closePanel() {
        guard panel.isVisible, !isClosing else { return }

        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            panel.orderOut(nil)
            statusItem.button?.highlight(false)
            return
        }

        presentationGeneration += 1
        let generation = presentationGeneration
        isClosing = true
        statusItem.button?.highlight(false)
        animatePanelClosing()

        DispatchQueue.main.asyncAfter(
            deadline: .now() + Metrics.presentationDuration
        ) { [weak self] in
            self?.finishClosingPanel(generation: generation)
        }
    }

    private func animatePanelOpening() {
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion,
              let layer = presentationLayer else { return }

        let opacity = CABasicAnimation(keyPath: "opacity")
        opacity.fromValue = 0
        opacity.toValue = 1

        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = Metrics.presentationScale
        scale.toValue = 1

        let group = CAAnimationGroup()
        group.animations = [opacity, scale]
        group.duration = Metrics.presentationDuration
        group.timingFunction = CAMediaTimingFunction(controlPoints: 0.22, 1, 0.36, 1)
        layer.add(group, forKey: "panelOpening")
    }

    private func animatePanelClosing() {
        guard let layer = presentationLayer else { return }

        let opacity = CABasicAnimation(keyPath: "opacity")
        opacity.fromValue = 1
        opacity.toValue = 0

        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 1
        scale.toValue = Metrics.presentationScale

        let group = CAAnimationGroup()
        group.animations = [opacity, scale]
        group.duration = Metrics.presentationDuration
        group.timingFunction = CAMediaTimingFunction(controlPoints: 0.64, 0, 0.78, 0)
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        layer.add(group, forKey: "panelClosing")
    }

    private func finishClosingPanel(generation: Int) {
        guard isClosing, presentationGeneration == generation else { return }
        panel.orderOut(nil)
        resetPresentationLayer()
        isClosing = false
    }

    private var presentationLayer: CALayer? {
        guard let view = hostingController?.view,
              let layer = view.layer else { return nil }

        view.layoutSubtreeIfNeeded()

        let desiredAnchor = CGPoint(x: 0.5, y: view.isFlipped ? 0 : 1)
        if layer.anchorPoint != desiredAnchor {
            let preservedFrame = layer.frame
            layer.anchorPoint = desiredAnchor
            layer.frame = preservedFrame
        }
        return layer
    }

    private func resetPresentationLayer() {
        guard let layer = presentationLayer else { return }
        layer.removeAnimation(forKey: "panelOpening")
        layer.removeAnimation(forKey: "panelClosing")
        layer.opacity = 1
        layer.transform = CATransform3DIdentity
    }

    private func updatePanelSize(_ proposedSize: CGSize) {
        guard proposedSize.width > 0, proposedSize.height > 0 else { return }

        let size = NSSize(width: DesignTokens.panelWidth, height: proposedSize.height)
        guard panel.contentLayoutRect.size != size else { return }

        panel.setContentSize(size)
        if panel.isVisible {
            positionPanel()
        }
    }

    private func positionPanel() {
        guard let button = statusItem.button,
              let buttonWindow = button.window else { return }

        let buttonRectInWindow = button.convert(button.bounds, to: nil)
        let anchorRect = buttonWindow.convertToScreen(buttonRectInWindow)
        let screen = buttonWindow.screen ?? NSScreen.main

        let proposedOrigin = NSPoint(
            x: anchorRect.midX - panel.frame.width / 2,
            y: anchorRect.minY - Metrics.panelGap - panel.frame.height
        )

        guard let visibleFrame = screen?.visibleFrame else {
            panel.setFrameOrigin(proposedOrigin)
            return
        }

        let minimumX = visibleFrame.minX + Metrics.screenInset
        let maximumX = visibleFrame.maxX - Metrics.screenInset - panel.frame.width
        let clampedX = min(max(proposedOrigin.x, minimumX), maximumX)

        panel.setFrameOrigin(NSPoint(x: clampedX, y: proposedOrigin.y))
    }
}

private final class StatusPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

private struct StatusPanelRoot: View {
    let model: AppModel
    let onSizeChange: @MainActor (CGSize) -> Void

    var body: some View {
        TimezonesPanel()
            .environment(model)
            .fixedSize(horizontal: true, vertical: true)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: PanelSizePreferenceKey.self, value: proxy.size)
                }
            }
            .onPreferenceChange(PanelSizePreferenceKey.self, perform: onSizeChange)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: DesignTokens.cornerRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: DesignTokens.cornerRadius,
                    style: .continuous
                )
                .stroke(Color(nsColor: .separatorColor).opacity(0.72), lineWidth: 1)
            }
    }
}

private struct PanelSizePreferenceKey: PreferenceKey {
    static let defaultValue = CGSize.zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
