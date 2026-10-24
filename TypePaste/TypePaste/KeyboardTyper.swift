//
//  KeyboardTyper.swift
//  TypePaste
//
//  Created by Tim Haselaars on 03/02/2026.
//

import ApplicationServices
import Foundation

@MainActor
final class KeyboardTyper {
    private let eventSource = CGEventSource(stateID: .privateState)

    var hasPressedModifiers: Bool {
        let flags = CGEventSource.flagsState(.hidSystemState)
        return !flags.intersection([.maskCommand, .maskControl, .maskAlternate, .maskShift]).isEmpty
    }

    func typeCharacter(_ character: Character) {
        guard let eventSource else { return }
        let unicodeScalars = Array(String(character).utf16)

        if let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: true) {
            keyDown.flags = []
            keyDown.keyboardSetUnicodeString(stringLength: unicodeScalars.count, unicodeString: unicodeScalars)
            keyDown.post(tap: .cghidEventTap)
        }

        if let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: false) {
            keyUp.flags = []
            keyUp.keyboardSetUnicodeString(stringLength: unicodeScalars.count, unicodeString: unicodeScalars)
            keyUp.post(tap: .cghidEventTap)
        }
    }
}

extension KeyboardTyper: KeyboardTyping {}
