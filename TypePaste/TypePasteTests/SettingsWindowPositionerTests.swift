import AppKit
import CoreGraphics
import Testing
@testable import TypePaste

@MainActor
@Suite(.serialized)
struct SettingsWindowPositionerTests {
    @Test
    func initialOriginCentersHorizontallyAndShiftsUp() {
        let frame = CGRect(x: 0, y: 0, width: 620, height: 640)
        let visible = CGRect(x: 100, y: 100, width: 1440, height: 900)

        let origin = SettingsWindowPositioner.initialOrigin(
            frame: frame,
            visibleFrame: visible,
            upwardOffset: 72
        )

        #expect(origin.x == 510)
        #expect(origin.y == 302)
    }

    @Test
    func originPreservesTopEdgeWhenProvided() {
        let frame = CGRect(x: 0, y: 0, width: 700, height: 700)
        let visible = CGRect(x: 100, y: 100, width: 1440, height: 900)

        let origin = SettingsWindowPositioner.initialOrigin(
            frame: frame,
            visibleFrame: visible,
            upwardOffset: 72,
            topEdge: 860
        )

        #expect(origin.y == 160)
    }

    @Test
    func resizedFrameStaysAttachedToPreviousTopEdgeWithinVisibleFrame() {
        let frame = SettingsWindowPositioner.resizedFrame(
            from: CGRect(x: 510, y: 172, width: 620, height: 640),
            visibleFrame: CGRect(x: 100, y: 100, width: 1440, height: 900),
            targetSize: NSSize(width: 620, height: 760)
        )

        #expect(frame.minY == 100)
        #expect(frame.maxY == 860)
    }

    @Test
    func resizedFrameRecentersHorizontallyForWiderSettingsTab() {
        let frame = SettingsWindowPositioner.resizedFrame(
            from: CGRect(x: 460, y: 272, width: 720, height: 520),
            visibleFrame: CGRect(x: 100, y: 100, width: 1440, height: 900),
            targetSize: NSSize(width: 840, height: 680)
        )

        #expect(frame.minX == 460)
        #expect(frame.maxY == 792)
    }

    @Test
    func resizedFrameKeepsTopLeftCornerFixedForTallerTab() {
        let currentFrame = CGRect(x: 460, y: 172, width: 840, height: 620)
        let frame = SettingsWindowPositioner.resizedFrame(
            from: currentFrame,
            visibleFrame: CGRect(x: 100, y: 100, width: 1440, height: 900),
            targetSize: NSSize(width: 840, height: 680)
        )

        #expect(frame.minX == currentFrame.minX)
        #expect(frame.maxY == currentFrame.maxY)
    }

    @Test
    func oversizedFramePinsToVisibleFrameOrigin() {
        let origin = SettingsWindowPositioner.initialOrigin(
            frame: CGRect(x: 0, y: 0, width: 1600, height: 980),
            visibleFrame: CGRect(x: 100, y: 100, width: 1440, height: 900),
            upwardOffset: 72
        )

        #expect(origin.x == 100)
        #expect(origin.y == 100)
    }

    @Test
    @MainActor
    func resizeObserverReappliesUsingPreviousTopEdgeDuringLiveResize() {
        let window = NSWindow(
            contentRect: CGRect(x: 510, y: 172, width: 620, height: 640),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        let initialTopEdge = window.frame.maxY

        var appliedTopEdge: CGFloat?
        let observer = SettingsWindowResizeObserver(window: window) { _, topEdge in
            appliedTopEdge = topEdge
        }

        observer.windowWillStartLiveResize(Notification(name: NSWindow.willStartLiveResizeNotification, object: window))
        window.setFrame(
            CGRect(
                x: window.frame.minX,
                y: 100,
                width: window.frame.width,
                height: window.frame.height + 120
            ),
            display: false
        )
        observer.windowDidResize(Notification(name: NSWindow.didResizeNotification, object: window))

        #expect(appliedTopEdge == initialTopEdge)
    }

    @Test
    @MainActor
    func initialPlacementStateIsStoredPerWindowInstance() {
        let firstWindow = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 620, height: 640),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        let secondWindow = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 620, height: 640),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        #expect(SettingsWindowPositioner.shouldApplyInitialPlacement(to: firstWindow) == true)
        #expect(SettingsWindowPositioner.shouldApplyInitialPlacement(to: firstWindow) == false)
        #expect(SettingsWindowPositioner.shouldApplyInitialPlacement(to: secondWindow) == true)
    }

    @Test
    func bestVisibleFramePrefersLargestIntersectionArea() {
        let windowFrame = CGRect(x: 700, y: 100, width: 500, height: 400)
        let candidates = [
            SettingsWindowPositioner.ScreenCandidate(
                frame: CGRect(x: 0, y: 0, width: 900, height: 900),
                visibleFrame: CGRect(x: 0, y: 0, width: 900, height: 860)
            ),
            SettingsWindowPositioner.ScreenCandidate(
                frame: CGRect(x: 800, y: 0, width: 900, height: 900),
                visibleFrame: CGRect(x: 800, y: 0, width: 900, height: 860)
            )
        ]

        let visibleFrame = SettingsWindowPositioner.bestVisibleFrame(
            for: windowFrame,
            candidates: candidates
        )

        #expect(visibleFrame == candidates[1].visibleFrame)
    }

    @Test
    func bestVisibleFrameFallsBackToNearestScreenCenter() {
        let windowFrame = CGRect(x: 2000, y: 200, width: 300, height: 300)
        let candidates = [
            SettingsWindowPositioner.ScreenCandidate(
                frame: CGRect(x: 0, y: 0, width: 900, height: 900),
                visibleFrame: CGRect(x: 0, y: 0, width: 900, height: 860)
            ),
            SettingsWindowPositioner.ScreenCandidate(
                frame: CGRect(x: 2400, y: 0, width: 900, height: 900),
                visibleFrame: CGRect(x: 2400, y: 0, width: 900, height: 860)
            )
        ]

        let visibleFrame = SettingsWindowPositioner.bestVisibleFrame(
            for: windowFrame,
            candidates: candidates
        )

        #expect(visibleFrame == candidates[1].visibleFrame)
    }
}
