//
//  TypePasteTests.swift
//  TypePasteTests
//
//  Created by Tim Haselaars on 03/02/2026.
//

import Carbon
import Testing
@testable import TypePaste

struct TypePasteTests {
    @Test
    func snippetHotKeyActionIdentifiersRoundTrip() {
        #expect(HotKeyAction.clipboard.id == 1)
        #expect(HotKeyAction.snippet(slot: 4).id == 104)
        #expect(HotKeyAction(id: 1) == .clipboard)
        #expect(HotKeyAction(id: 104) == .snippet(slot: 4))
        #expect(HotKeyAction(id: 999) == nil)
    }

    @Test
    func primaryHotKeyReservesShiftForSnippetShortcuts() {
        let sanitized = HotKeySettings.sanitizeModifiers(UInt32(cmdKey | optionKey | shiftKey))

        #expect((sanitized & UInt32(cmdKey)) != 0)
        #expect((sanitized & UInt32(optionKey)) != 0)
        #expect((sanitized & UInt32(shiftKey)) == 0)
    }
}
