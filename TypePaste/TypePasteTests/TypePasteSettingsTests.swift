import AppKit
import Testing
@testable import TypePaste

struct TypePasteSettingsTests {
    @Test
    func tabsExposePulseStyleMetadata() {
        #expect(TypePasteSettingsTab.allCases.map(\.title) == ["General", "Snippet Library", "About"])
        #expect(TypePasteSettingsTab.general.icon == "gearshape")
        #expect(TypePasteSettingsTab.snippets.icon == "text.badge.plus")
        #expect(TypePasteSettingsTab.about.icon == "info.circle")
    }

    @Test
    func settingsTabsExposeExpectedWindowSizes() {
        let generalSize = TypePasteSettingsTab.general.preferredWindowSize
        let snippetSize = TypePasteSettingsTab.snippets.preferredWindowSize
        let aboutSize = TypePasteSettingsTab.about.preferredWindowSize

        #expect(generalSize == NSSize(width: 840, height: 620))
        #expect(snippetSize == NSSize(width: 840, height: 680))
        #expect(aboutSize == NSSize(width: 840, height: 420))
    }

    @Test
    func aboutVersionTextIncludesVersionAndBuild() {
        #expect(ContentView.aboutVersionText(shortVersion: "1.0", buildNumber: "1") == "Version 1.0 (1)")
    }

    @Test
    func aboutVersionTextOmitsBuildWhenUnavailable() {
        #expect(ContentView.aboutVersionText(shortVersion: "1.0", buildNumber: nil) == "Version 1.0")
    }

    @Test
    func settingsTabSwitchResizeDoesNotAnimate() {
        #expect(ContentView.shouldAnimateResize(for: .general) == false)
        #expect(ContentView.shouldAnimateResize(for: .snippets) == false)
        #expect(ContentView.shouldAnimateResize(for: .about) == false)
    }

    @Test
    func generalSettingsLayoutUsesSharedCenteredColumnWidth() {
        #expect(ContentView.settingsColumnWidth == 520)
    }

    @Test
    func existingSettingsWindowMatchesRegisteredIdentifier() {
        let otherWindow = NSWindow()
        let settingsWindow = NSWindow()
        settingsWindow.identifier = SettingsWindowPositioner.settingsWindowIdentifier

        #expect(
            SettingsWindowPositioner.existingSettingsWindow(from: [otherWindow, settingsWindow]) === settingsWindow
        )
    }
}
