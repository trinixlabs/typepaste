import AppKit
import CoreGraphics
import OSLog
import ObjectiveC
import SwiftUI

enum SettingsWindowPositioner {
    static let upwardOffset: CGFloat = 72
    private static var initialPlacementAppliedAssociationKey: UInt8 = 0
    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.trinix.TypePaste",
        category: "Windowing"
    )

    struct ScreenCandidate {
        let frame: CGRect
        let visibleFrame: CGRect
    }

    static func initialOrigin(
        frame: CGRect,
        visibleFrame: CGRect,
        upwardOffset: CGFloat = upwardOffset,
        topEdge: CGFloat? = nil
    ) -> CGPoint {
        let centeredX = visibleFrame.minX + (visibleFrame.width - frame.width) / 2
        let minX = visibleFrame.minX
        let maxX = visibleFrame.maxX - frame.width

        let rawY: CGFloat
        if let topEdge {
            rawY = topEdge - frame.height
        } else {
            let centeredY = visibleFrame.minY + (visibleFrame.height - frame.height) / 2
            rawY = centeredY + upwardOffset
        }

        let minY = visibleFrame.minY
        let maxY = visibleFrame.maxY - frame.height

        return CGPoint(
            x: clampedOrigin(for: centeredX, minBound: minX, maxBound: maxX),
            y: clampedOrigin(for: rawY, minBound: minY, maxBound: maxY)
        )
    }

    static func bestVisibleFrame(for windowFrame: CGRect, candidates: [ScreenCandidate]) -> CGRect {
        guard let bestCandidate = candidates.max(by: {
            compareScreenCandidates($0, $1, for: windowFrame) == .orderedAscending
        }) else {
            return windowFrame
        }

        return bestCandidate.visibleFrame
    }

    static func visibleFrame(for window: NSWindow) -> CGRect {
        if let screen = window.screen {
            return screen.visibleFrame
        }

        let candidates = NSScreen.screens.map { screen in
            ScreenCandidate(frame: screen.frame, visibleFrame: screen.visibleFrame)
        }
        return bestVisibleFrame(for: window.frame, candidates: candidates)
    }

    static func apply(window: NSWindow, visibleFrame: CGRect, topEdge: CGFloat? = nil) {
        let origin = initialOrigin(
            frame: window.frame,
            visibleFrame: visibleFrame,
            upwardOffset: upwardOffset,
            topEdge: topEdge
        )

        logger.debug(
            """
            Applying settings window origin number=\(window.windowNumber) \
            frame=\(window.frame.debugDescription, privacy: .public) \
            visible=\(visibleFrame.debugDescription, privacy: .public) \
            topEdge=\(topEdge.map(String.init(describing:)) ?? "nil", privacy: .public) \
            origin=\(origin.debugDescription, privacy: .public)
            """
        )
        window.setFrameOrigin(origin)
    }

    static func apply(window: NSWindow, topEdge: CGFloat? = nil) {
        apply(window: window, visibleFrame: visibleFrame(for: window), topEdge: topEdge)
    }

    static func resizedFrame(from currentFrame: CGRect, visibleFrame: CGRect, targetSize: CGSize) -> CGRect {
        let minX = clampedOrigin(
            for: currentFrame.minX,
            minBound: visibleFrame.minX,
            maxBound: visibleFrame.maxX - targetSize.width
        )
        let maxY = min(currentFrame.maxY, visibleFrame.maxY)
        let minY = clampedOrigin(
            for: maxY - targetSize.height,
            minBound: visibleFrame.minY,
            maxBound: visibleFrame.maxY - targetSize.height
        )

        return CGRect(
            x: minX,
            y: minY,
            width: targetSize.width,
            height: targetSize.height
        )
    }

    static func shouldApplyInitialPlacement(to window: NSWindow) -> Bool {
        if let hasApplied = objc_getAssociatedObject(window, &initialPlacementAppliedAssociationKey) as? NSNumber,
           hasApplied.boolValue {
            logger.debug("Skipping initial settings placement for window number=\(window.windowNumber)")
            return false
        }

        objc_setAssociatedObject(
            window,
            &initialPlacementAppliedAssociationKey,
            NSNumber(value: true),
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        logger.info("Marking initial settings placement for window number=\(window.windowNumber)")
        return true
    }

    private static func clampedOrigin(for value: CGFloat, minBound: CGFloat, maxBound: CGFloat) -> CGFloat {
        guard maxBound >= minBound else {
            return minBound
        }

        return min(max(value, minBound), maxBound)
    }

    private static func compareScreenCandidates(
        _ lhs: ScreenCandidate,
        _ rhs: ScreenCandidate,
        for windowFrame: CGRect
    ) -> ComparisonResult {
        let lhsIntersectionArea = intersectionArea(between: lhs.frame, and: windowFrame)
        let rhsIntersectionArea = intersectionArea(between: rhs.frame, and: windowFrame)

        if lhsIntersectionArea != rhsIntersectionArea {
            return lhsIntersectionArea < rhsIntersectionArea ? .orderedAscending : .orderedDescending
        }

        let windowCenter = CGPoint(x: windowFrame.midX, y: windowFrame.midY)
        let lhsDistance = squaredDistance(from: windowCenter, to: CGPoint(x: lhs.frame.midX, y: lhs.frame.midY))
        let rhsDistance = squaredDistance(from: windowCenter, to: CGPoint(x: rhs.frame.midX, y: rhs.frame.midY))

        if lhsDistance != rhsDistance {
            return lhsDistance > rhsDistance ? .orderedAscending : .orderedDescending
        }

        return .orderedSame
    }

    private static func intersectionArea(between lhs: CGRect, and rhs: CGRect) -> CGFloat {
        let intersection = lhs.intersection(rhs)
        guard !intersection.isNull else {
            return 0
        }

        return intersection.width * intersection.height
    }

    private static func squaredDistance(from lhs: CGPoint, to rhs: CGPoint) -> CGFloat {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return dx * dx + dy * dy
    }
}

final class SettingsWindowResizeObserver {
    private weak var window: NSWindow?
    private let applyPosition: (NSWindow, CGFloat) -> Void
    private let notificationCenter: NotificationCenter
    private var observers: [NSObjectProtocol] = []
    private var isLiveResizing = false
    private var topEdgeBeforeResize: CGFloat?

    init(
        window: NSWindow,
        notificationCenter: NotificationCenter = .default,
        applyPosition: @escaping (NSWindow, CGFloat) -> Void = { window, topEdge in
            SettingsWindowPositioner.apply(window: window, topEdge: topEdge)
        }
    ) {
        self.window = window
        self.notificationCenter = notificationCenter
        self.applyPosition = applyPosition
        observers = [
            notificationCenter.addObserver(
                forName: NSWindow.willStartLiveResizeNotification,
                object: window,
                queue: nil
            ) { [weak self] notification in
                self?.windowWillStartLiveResize(notification)
            },
            notificationCenter.addObserver(
                forName: NSWindow.didResizeNotification,
                object: window,
                queue: nil
            ) { [weak self] notification in
                self?.windowDidResize(notification)
            },
            notificationCenter.addObserver(
                forName: NSWindow.didEndLiveResizeNotification,
                object: window,
                queue: nil
            ) { [weak self] notification in
                self?.windowDidEndLiveResize(notification)
            }
        ]
    }

    deinit {
        for observer in observers {
            notificationCenter.removeObserver(observer)
        }
    }

    func windowWillStartLiveResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        isLiveResizing = true
        topEdgeBeforeResize = window.frame.maxY
        SettingsWindowPositioner.logger.debug(
            "Settings window will start live resize number=\(window.windowNumber) topEdge=\(window.frame.maxY)"
        )
    }

    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        guard isLiveResizing, let topEdgeBeforeResize else { return }

        SettingsWindowPositioner.logger.debug(
            "Settings window did resize number=\(window.windowNumber) frame=\(window.frame.debugDescription, privacy: .public) topEdge=\(topEdgeBeforeResize)"
        )
        applyPosition(window, topEdgeBeforeResize)
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        guard notification.object as? NSWindow === window else { return }

        isLiveResizing = false
        topEdgeBeforeResize = nil
        if let window {
            SettingsWindowPositioner.logger.debug("Settings window ended live resize number=\(window.windowNumber)")
        }
    }
}

struct SettingsWindowAccessor: NSViewRepresentable {
    var onWindowResolved: ((NSWindow) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(onWindowResolved: onWindowResolved)
    }

    func makeNSView(context: Context) -> WindowAccessorView {
        let view = WindowAccessorView()
        view.onWindowAvailable = { window in
            context.coordinator.connect(to: window)
        }
        return view
    }

    func updateNSView(_ nsView: WindowAccessorView, context: Context) {
        context.coordinator.onWindowResolved = onWindowResolved
        nsView.onWindowAvailable = { window in
            context.coordinator.connect(to: window)
        }

        if let window = nsView.window {
            context.coordinator.connect(to: window)
        }
    }

    final class Coordinator {
        private static var resizeObserverAssociationKey: UInt8 = 0
        var onWindowResolved: ((NSWindow) -> Void)?

        init(onWindowResolved: ((NSWindow) -> Void)? = nil) {
            self.onWindowResolved = onWindowResolved
        }

        func connect(to window: NSWindow) {
            installResizeObserverIfNeeded(on: window)
            onWindowResolved?(window)

            guard SettingsWindowPositioner.shouldApplyInitialPlacement(to: window) else {
                return
            }

            SettingsWindowPositioner.apply(
                window: window,
                visibleFrame: SettingsWindowPositioner.visibleFrame(for: window)
            )
        }

        private func installResizeObserverIfNeeded(on window: NSWindow) {
            if objc_getAssociatedObject(window, &Self.resizeObserverAssociationKey) as? SettingsWindowResizeObserver != nil {
                return
            }

            let observer = SettingsWindowResizeObserver(window: window) { window, topEdge in
                SettingsWindowPositioner.apply(
                    window: window,
                    visibleFrame: SettingsWindowPositioner.visibleFrame(for: window),
                    topEdge: topEdge
                )
            }

            objc_setAssociatedObject(
                window,
                &Self.resizeObserverAssociationKey,
                observer,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

final class WindowAccessorView: NSView {
    var onWindowAvailable: ((NSWindow) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if let window {
            onWindowAvailable?(window)
        }
    }
}
