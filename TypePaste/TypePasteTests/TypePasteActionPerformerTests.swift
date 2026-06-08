import Foundation
import Testing
@testable import TypePaste

struct TypePasteActionPerformerTests {
    @Test
    func clipboardActionUsesClipboardTyping() {
        let typingActionHandler = TestTypingActionHandler()
        let performer = TypePasteActionPerformer(typingActionHandler: typingActionHandler)

        performer.perform(.clipboard, snippets: [])

        #expect(typingActionHandler.didTypeClipboard == true)
        #expect(typingActionHandler.typedTexts.isEmpty)
    }

    @Test
    func snippetActionTypesExpectedSnippetText() {
        let typingActionHandler = TestTypingActionHandler()
        let performer = TypePasteActionPerformer(typingActionHandler: typingActionHandler)
        let snippets = [
            Snippet(id: UUID(), title: "First", text: "alpha", order: 0),
            Snippet(id: UUID(), title: "Second", text: "beta", order: 1),
        ]

        performer.perform(.snippet(slot: 2), snippets: snippets)

        #expect(typingActionHandler.didTypeClipboard == false)
        #expect(typingActionHandler.typedTexts == ["beta"])
    }

    @Test
    func missingSnippetSlotDoesNothing() {
        let typingActionHandler = TestTypingActionHandler()
        let performer = TypePasteActionPerformer(typingActionHandler: typingActionHandler)

        performer.perform(.snippet(slot: 3), snippets: [
            Snippet(id: UUID(), title: "Only", text: "value", order: 0),
        ])

        #expect(typingActionHandler.didTypeClipboard == false)
        #expect(typingActionHandler.typedTexts.isEmpty)
    }
}

private final class TestTypingActionHandler: TypingActionHandling {
    private(set) var didTypeClipboard = false
    private(set) var typedTexts: [String] = []

    func typeClipboardContents() {
        didTypeClipboard = true
    }

    func typeText(_ text: String) {
        typedTexts.append(text)
    }
}
