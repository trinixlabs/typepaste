//
//  Snippet.swift
//  TypePaste
//
//  Created by Codex on 08/06/2026.
//

import Carbon
import Foundation

struct Snippet: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var text: String
    var order: Int

    var displayTitle: String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty {
            return trimmedTitle
        }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            return trimmedText
        }

        return "Untitled Snippet"
    }
}

enum SnippetLibrarySettings {
    static let snippetsKey = "snippets.items"
    static let maxHotKeySnippets = 9

    static func load(from defaults: UserDefaults = .standard) -> [Snippet] {
        guard let data = defaults.data(forKey: snippetsKey) else { return [] }
        guard let snippets = try? JSONDecoder().decode([Snippet].self, from: data) else { return [] }
        return normalized(snippets)
    }

    static func save(_ snippets: [Snippet], in defaults: UserDefaults = .standard) {
        let normalizedSnippets = normalized(snippets)
        guard let data = try? JSONEncoder().encode(normalizedSnippets) else { return }
        defaults.set(data, forKey: snippetsKey)
    }

    static func normalized(_ snippets: [Snippet]) -> [Snippet] {
        snippets
            .sorted { lhs, rhs in
                if lhs.order == rhs.order {
                    return lhs.id.uuidString < rhs.id.uuidString
                }
                return lhs.order < rhs.order
            }
            .enumerated()
            .map { index, snippet in
                var snippet = snippet
                snippet.order = index
                return snippet
            }
    }
}

struct SnippetHotKeyAssignment: Equatable {
    let slot: Int
    let snippet: Snippet
    let keyCode: Int
    let modifiers: UInt32
}

enum SnippetHotKeyMapping {
    static func assignments(snippets: [Snippet], baseModifiers: UInt32) -> [SnippetHotKeyAssignment] {
        let modifiers = HotKeySettings.snippetModifiers(baseModifiers: baseModifiers)

        return SnippetLibrarySettings.normalized(snippets)
            .prefix(SnippetLibrarySettings.maxHotKeySnippets)
            .enumerated()
            .compactMap { index, snippet in
                let slot = index + 1
                guard let keyCode = HotKeySettings.snippetKeyCode(for: slot) else { return nil }
                return SnippetHotKeyAssignment(
                    slot: slot,
                    snippet: snippet,
                    keyCode: keyCode,
                    modifiers: modifiers
                )
            }
    }
}
