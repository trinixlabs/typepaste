import Foundation
import Testing
@testable import TypePaste

struct TypePasteMenuStateTests {
    @Test
    func firstNineSnippetsIncludeShortcutHints() {
        let snippets = (1...10).map { index in
            Snippet(id: UUID(), title: "Snippet \(index)", text: "\(index)", order: index - 1)
        }

        let state = TypePasteMenuState(
            clipboardShortcut: "⌘1",
            snippets: snippets,
            snippetAssignments: SnippetHotKeyMapping.assignments(
                snippets: snippets,
                baseModifiers: 0
            )
        )

        #expect(state.menuSnippets[0].title == "Snippet 1")
        #expect(state.menuSnippets[0].shortcutHint == "⇧⌘1")
        #expect(state.menuSnippets[8].shortcutHint == "⇧⌘9")
        #expect(state.menuSnippets[9].shortcutHint == nil)
    }
}
