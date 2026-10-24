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
    private var registrations: [HotKeyRegistration]
    private var pressState = HotKeyPressState()

    init(registrations: [HotKeyRegistration]) {
        self.registrations = registrations
        registerHotKeys(registrations)
    }

    deinit {
        unregisterHotKey()
    }

    func update(registrations: [HotKeyRegistration]) {
        guard registrations != self.registrations else { return }
        self.registrations = registrations
        unregisterHotKey()
        registerHotKeys(registrations)
    }

    private func registerHotKeys(_ registrations: [HotKeyRegistration]) {
        unregisterHotKey()

        var eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased)),
        ]

        InstallEventHandler(
            GetEventDispatcherTarget(),
            HotKeyManager.hotKeyHandler,
            eventTypes.count,
            &eventTypes,
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
        pressState = HotKeyPressState()

        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
    }

    private func handleHotKeyEvent(id: UInt32, isPressed: Bool) {
        if pressState.handle(id: id, isPressed: isPressed) {
            onHotKeyPressed?(id)
        }
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
        guard status == noErr, hotKeyID.signature == "TPST".fourCharCode else { return noErr }

        let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
        manager.handleHotKeyEvent(id: hotKeyID.id, isPressed: GetEventKind(eventRef) == UInt32(kEventHotKeyPressed))
        return noErr
    }
}

struct HotKeyPressState {
    private var pressedIDs: Set<UInt32> = []

    mutating func handle(id: UInt32, isPressed: Bool) -> Bool {
        if isPressed {
            return pressedIDs.insert(id).inserted
        }
        pressedIDs.remove(id)
        return false
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
