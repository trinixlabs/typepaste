import Carbon
import Foundation
import Testing
@testable import TypePaste

@Suite(.serialized)
struct SnippetLibraryTests {
    @Test
    func snippetsRoundTripWithStableOrder() throws {
        let defaults = UserDefaults.standard
        resetSnippets(in: defaults)

        let snippets = [
            Snippet(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, title: "Second", text: "beta", order: 1),
            Snippet(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, title: "First", text: "alpha", order: 0),
        ]

        SnippetLibrarySettings.save(snippets, in: defaults)
        let restored = try #require(SnippetLibrarySettings.load(from: defaults))

        #expect(restored.map(\.title) == ["First", "Second"])
        #expect(restored.map(\.text) == ["alpha", "beta"])
        #expect(restored.map(\.order) == [0, 1])
    }

    @Test
    func normalizeReordersSnippetsIntoSequentialSlots() {
        let snippets = [
            Snippet(id: UUID(), title: "Three", text: "3", order: 7),
            Snippet(id: UUID(), title: "One", text: "1", order: 1),
            Snippet(id: UUID(), title: "Two", text: "2", order: 4),
        ]

        let normalized = SnippetLibrarySettings.normalized(snippets)

        #expect(normalized.map(\.title) == ["One", "Two", "Three"])
        #expect(normalized.map(\.order) == [0, 1, 2])
    }

    @Test
    func firstNineSnippetsReceiveShiftHotKeySlots() {
        let snippets = (1...11).map { index in
            Snippet(id: UUID(), title: "Snippet \(index)", text: "\(index)", order: index - 1)
        }

        let assignments = SnippetHotKeyMapping.assignments(
            snippets: snippets,
            baseModifiers: UInt32(cmdKey | optionKey)
        )

        #expect(assignments.count == 9)
        #expect(assignments.first?.slot == 1)
        #expect(assignments.first?.snippet.title == "Snippet 1")
        #expect(assignments.first?.keyCode == Int(kVK_ANSI_1))
        #expect(assignments.first?.modifiers == UInt32(cmdKey | optionKey | shiftKey))
        #expect(assignments.last?.slot == 9)
        #expect(assignments.last?.snippet.title == "Snippet 9")
        #expect(assignments.last?.keyCode == Int(kVK_ANSI_9))
    }

    private func resetSnippets(in defaults: UserDefaults) {
        defaults.removeObject(forKey: SnippetLibrarySettings.snippetsKey)
    }
}
