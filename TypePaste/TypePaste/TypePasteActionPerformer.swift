//
//  TypePasteActionPerformer.swift
//  TypePaste
//
//  Created by Codex on 08/06/2026.
//

import Foundation

protocol TypingActionHandling {
    func typeClipboardContents()
    func typeText(_ text: String)
}

enum HotKeyAction: Equatable {
    case clipboard
    case snippet(slot: Int)

    init?(id: UInt32) {
        if id == 1 {
            self = .clipboard
            return
        }

        let slot = Int(id) - 100
        guard (1...SnippetLibrarySettings.maxHotKeySnippets).contains(slot) else {
            return nil
        }
        self = .snippet(slot: slot)
    }

    var id: UInt32 {
        switch self {
        case .clipboard:
            return 1
        case .snippet(let slot):
            return UInt32(100 + slot)
        }
    }
}

struct TypePasteActionPerformer {
    let typingActionHandler: TypingActionHandling

    func perform(_ action: HotKeyAction, snippets: [Snippet]) {
        switch action {
        case .clipboard:
            typingActionHandler.typeClipboardContents()
        case .snippet(let slot):
            let orderedSnippets = SnippetLibrarySettings.normalized(snippets)
            guard orderedSnippets.indices.contains(slot - 1) else { return }
            typingActionHandler.typeText(orderedSnippets[slot - 1].text)
        }
    }
}
