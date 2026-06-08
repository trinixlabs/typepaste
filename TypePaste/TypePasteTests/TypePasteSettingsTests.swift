import AppKit
import Testing
@testable import TypePaste

struct TypePasteSettingsTests {
    @Test
    func tabsExposePulseStyleMetadata() {
        #expect(TypePasteSettingsTab.allCases.map(\.title) == ["General", "Snippet Library"])
        #expect(TypePasteSettingsTab.general.icon == "gearshape")
        #expect(TypePasteSettingsTab.snippets.icon == "text.badge.plus")
    }

    @Test
    func snippetLibraryPrefersLargerWindowThanGeneral() {
        let generalSize = TypePasteSettingsTab.general.preferredWindowSize
        let snippetSize = TypePasteSettingsTab.snippets.preferredWindowSize

        #expect(generalSize == NSSize(width: 720, height: 520))
        #expect(snippetSize == NSSize(width: 840, height: 680))
    }
}
