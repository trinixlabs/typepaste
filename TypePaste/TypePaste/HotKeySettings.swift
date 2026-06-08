//
//  HotKeySettings.swift
//  TypePaste
//
//  Created by Tim Haselaars on 03/02/2026.
//

import Carbon
import Foundation

struct HotKeySettings {
    static let keyCodeKey = "hotkey.keyCode"
    static let modifiersKey = "hotkey.modifiers"

    static let availableKeys: [HotKeyKey] = [
        .init(name: "1", keyCode: kVK_ANSI_1),
        .init(name: "2", keyCode: kVK_ANSI_2),
        .init(name: "3", keyCode: kVK_ANSI_3),
        .init(name: "4", keyCode: kVK_ANSI_4),
        .init(name: "5", keyCode: kVK_ANSI_5),
        .init(name: "6", keyCode: kVK_ANSI_6),
        .init(name: "7", keyCode: kVK_ANSI_7),
        .init(name: "8", keyCode: kVK_ANSI_8),
        .init(name: "9", keyCode: kVK_ANSI_9),
        .init(name: "0", keyCode: kVK_ANSI_0),
        .init(name: "A", keyCode: kVK_ANSI_A),
        .init(name: "B", keyCode: kVK_ANSI_B),
        .init(name: "C", keyCode: kVK_ANSI_C),
        .init(name: "D", keyCode: kVK_ANSI_D),
        .init(name: "E", keyCode: kVK_ANSI_E),
        .init(name: "F", keyCode: kVK_ANSI_F),
        .init(name: "G", keyCode: kVK_ANSI_G),
        .init(name: "H", keyCode: kVK_ANSI_H),
        .init(name: "I", keyCode: kVK_ANSI_I),
        .init(name: "J", keyCode: kVK_ANSI_J),
        .init(name: "K", keyCode: kVK_ANSI_K),
        .init(name: "L", keyCode: kVK_ANSI_L),
        .init(name: "M", keyCode: kVK_ANSI_M),
        .init(name: "N", keyCode: kVK_ANSI_N),
        .init(name: "O", keyCode: kVK_ANSI_O),
        .init(name: "P", keyCode: kVK_ANSI_P),
        .init(name: "Q", keyCode: kVK_ANSI_Q),
        .init(name: "R", keyCode: kVK_ANSI_R),
        .init(name: "S", keyCode: kVK_ANSI_S),
        .init(name: "T", keyCode: kVK_ANSI_T),
        .init(name: "U", keyCode: kVK_ANSI_U),
        .init(name: "V", keyCode: kVK_ANSI_V),
        .init(name: "W", keyCode: kVK_ANSI_W),
        .init(name: "X", keyCode: kVK_ANSI_X),
        .init(name: "Y", keyCode: kVK_ANSI_Y),
        .init(name: "Z", keyCode: kVK_ANSI_Z),
    ]

    static var keyCode: UInt32 {
        let stored = UserDefaults.standard.integer(forKey: keyCodeKey)
        return stored > 0 ? UInt32(stored) : UInt32(kVK_ANSI_1)
    }

    static var modifiers: UInt32 {
        let stored = UserDefaults.standard.integer(forKey: modifiersKey)
        let base = stored > 0 ? UInt32(stored) : UInt32(cmdKey)
        return sanitizeModifiers(base)
    }

    static func sanitizeModifiers(_ value: UInt32) -> UInt32 {
        let withCommand = value | UInt32(cmdKey)
        return withCommand & ~UInt32(shiftKey)
    }

    static func snippetModifiers(baseModifiers: UInt32) -> UInt32 {
        sanitizeModifiers(baseModifiers) | UInt32(shiftKey)
    }

    static func snippetKeyCode(for slot: Int) -> Int? {
        switch slot {
        case 1: return kVK_ANSI_1
        case 2: return kVK_ANSI_2
        case 3: return kVK_ANSI_3
        case 4: return kVK_ANSI_4
        case 5: return kVK_ANSI_5
        case 6: return kVK_ANSI_6
        case 7: return kVK_ANSI_7
        case 8: return kVK_ANSI_8
        case 9: return kVK_ANSI_9
        default: return nil
        }
    }

    static func snippetDisplayString(slot: Int, baseModifiers: UInt32) -> String {
        guard let keyCode = snippetKeyCode(for: slot) else { return "" }
        return displayString(keyCode: UInt32(keyCode), modifiers: snippetModifiers(baseModifiers: baseModifiers))
    }

    static func displayString(keyCode: UInt32, modifiers: UInt32) -> String {
        var parts: [String] = []
        if (modifiers & UInt32(controlKey)) != 0 { parts.append("⌃") }
        if (modifiers & UInt32(optionKey)) != 0 { parts.append("⌥") }
        if (modifiers & UInt32(shiftKey)) != 0 { parts.append("⇧") }
        if (modifiers & UInt32(cmdKey)) != 0 { parts.append("⌘") }

        let keyName = availableKeys.first(where: { UInt32($0.keyCode) == keyCode })?.name ?? "?"
        parts.append(keyName)
        return parts.joined()
    }
}

struct HotKeyKey: Identifiable, Hashable {
    let name: String
    let keyCode: Int

    var id: Int { keyCode }
}
