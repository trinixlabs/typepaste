//
//  ClipboardTyper.swift
//  TypePaste
//
//  Created by Tim Haselaars on 03/02/2026.
//

import AppKit

protocol PasteboardReading {
    func string(forType type: NSPasteboard.PasteboardType) -> String?
}

@MainActor
protocol KeyboardTyping {
    var hasPressedModifiers: Bool { get }
    func typeCharacter(_ character: Character)
}

protocol Beeping {
    func beep()
}

@MainActor
final class ClipboardTyper {
    private let pasteboard: PasteboardReading
    private let sessions: TypingSessionController
    private let beeper: Beeping

    convenience init() {
        self.init(keyboardTyper: KeyboardTyper())
    }

    init(
        pasteboard: PasteboardReading = NSPasteboard.general,
        keyboardTyper: KeyboardTyping,
        beeper: Beeping = NSSoundBeeper()
    ) {
        self.pasteboard = pasteboard
        self.sessions = TypingSessionController(keyboardTyper: keyboardTyper)
        self.beeper = beeper
    }

    func typeClipboardContents() {
        if sessions.handleRepeatedHotkey(TypingSettings.repeatedHotkeyAction) { return }

        guard let rawText = pasteboard.string(forType: .string) else {
            beeper.beep()
            return
        }

        typeText(rawText)
    }

    func typeText(_ rawText: String) {
        let text = rawText.trimmingCharacters(in: .newlines)
        guard !text.isEmpty else {
            beeper.beep()
            return
        }

        sessions.start(
            text,
            initialDelay: TypingSettings.initialDelay,
            perCharacterDelay: TypingSettings.delayPerCharacter
        )
    }
}

extension ClipboardTyper: TypingActionHandling {}

extension NSPasteboard: PasteboardReading {}

struct NSSoundBeeper: Beeping {
    func beep() {
        NSSound.beep()
    }
}
