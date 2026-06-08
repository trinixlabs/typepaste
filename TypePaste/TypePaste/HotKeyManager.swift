//
//  HotKeyManager.swift
//  TypePaste
//
//  Created by Tim Haselaars on 03/02/2026.
//

import Carbon
import Foundation

final class HotKeyManager {
    var onHotKeyPressed: ((UInt32) -> Void)?

    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var handlerRef: EventHandlerRef?

    init(registrations: [HotKeyRegistration]) {
        registerHotKeys(registrations)
    }

    deinit {
        unregisterHotKey()
    }

    func update(registrations: [HotKeyRegistration]) {
        unregisterHotKey()
        registerHotKeys(registrations)
    }

    private func registerHotKeys(_ registrations: [HotKeyRegistration]) {
        unregisterHotKey()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetEventDispatcherTarget(),
            HotKeyManager.hotKeyHandler,
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &handlerRef
        )

        for registration in registrations {
            var hotKeyRef: EventHotKeyRef?
            let hotKeyID = EventHotKeyID(signature: "TPST".fourCharCode, id: registration.id)
            let status = RegisterEventHotKey(
                UInt32(registration.keyCode),
                registration.modifiers,
                hotKeyID,
                GetEventDispatcherTarget(),
                0,
                &hotKeyRef
            )

            guard status == noErr, let hotKeyRef else { continue }
            hotKeyRefs[registration.id] = hotKeyRef
        }
    }

    private func unregisterHotKey() {
        for hotKeyRef in hotKeyRefs.values {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRefs.removeAll()

        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
    }

    private func handleHotKeyPressed(id: UInt32) {
        onHotKeyPressed?(id)
    }

    private static let hotKeyHandler: EventHandlerUPP = { _, eventRef, userData in
        guard let userData else { return noErr }
        guard let eventRef else { return noErr }

        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            eventRef,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        guard status == noErr else { return noErr }

        let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
        manager.handleHotKeyPressed(id: hotKeyID.id)
        return noErr
    }
}

struct HotKeyRegistration: Equatable {
    let id: UInt32
    let keyCode: Int
    let modifiers: UInt32
}

private extension String {
    var fourCharCode: FourCharCode {
        var result: FourCharCode = 0
        for scalar in unicodeScalars.prefix(4) {
            result = (result << 8) + FourCharCode(scalar.value)
        }
        return result
    }
}
