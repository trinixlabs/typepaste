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

protocol KeyboardTyping {
    func typeText(_ text: String)
}

protocol Beeping {
    func beep()
}

protocol WorkQueueing {
    func async(_ operation: @escaping @Sendable () -> Void)
}

final class ClipboardTyper {
    private let pasteboard: PasteboardReading
    private let keyboardTyper: KeyboardTyping
    private let beeper: Beeping
    private let workQueue: WorkQueueing

    init(
        pasteboard: PasteboardReading = NSPasteboard.general,
        keyboardTyper: KeyboardTyping = KeyboardTyper(),
        beeper: Beeping = NSSoundBeeper(),
        workQueue: WorkQueueing = GlobalUserInitiatedQueue()
    ) {
        self.pasteboard = pasteboard
        self.keyboardTyper = keyboardTyper
        self.beeper = beeper
        self.workQueue = workQueue
    }

    func typeClipboardContents() {
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

        workQueue.async { [keyboardTyper] in
            keyboardTyper.typeText(text)
        }
    }
}

extension ClipboardTyper: TypingActionHandling {}

extension NSPasteboard: PasteboardReading {}

struct NSSoundBeeper: Beeping {
    func beep() {
        NSSound.beep()
    }
}

struct GlobalUserInitiatedQueue: WorkQueueing {
    func async(_ operation: @escaping @Sendable () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async(execute: operation)
    }
}
