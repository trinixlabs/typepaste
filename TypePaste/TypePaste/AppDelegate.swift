//
//  AppDelegate.swift
//  TypePaste
//
//  Created by Tim Haselaars on 03/02/2026.
//

import AppKit
import ApplicationServices
import Carbon

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let clipboardTyper = ClipboardTyper()
    private var hotKeyManager: HotKeyManager?
    private var hotKeyObserver: NSObjectProtocol?
    private weak var typeClipboardMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Keep launch minimal and perform setup on the next main-loop turn.
        // This avoids first-launch timing issues while macOS is presenting trust prompts.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.requestAccessibilityPermission()
            NSApp.setActivationPolicy(.accessory)
            self.setUpStatusItem()
            self.setUpHotKey()
            self.observeHotKeyChanges()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager = nil
        hotKeyObserver = nil
    }

    private func setUpStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "TypePaste")

        let menu = NSMenu()
        let typeItem = NSMenuItem(
            title: "Type Clipboard (\(HotKeySettings.displayString(keyCode: HotKeySettings.keyCode, modifiers: HotKeySettings.modifiers)))",
            action: #selector(typeClipboard),
            keyEquivalent: ""
        )
        menu.addItem(typeItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))
        menu.addItem(NSMenuItem(
            title: "Quit TypePaste",
            action: #selector(quitApp),
            keyEquivalent: "q"
        ))
        statusItem.menu = menu

        self.statusItem = statusItem
        self.typeClipboardMenuItem = typeItem
    }

    private func setUpHotKey() {
        updateHotKeyFromSettings()
    }

    private func observeHotKeyChanges() {
        hotKeyObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateHotKeyFromSettings()
        }
    }

    private func updateHotKeyFromSettings() {
        let keyCode = Int(HotKeySettings.keyCode)
        let modifiers = HotKeySettings.modifiers

        if let hotKeyManager {
            hotKeyManager.update(keyCode: keyCode, modifiers: modifiers)
        } else {
            hotKeyManager = HotKeyManager(keyCode: keyCode, modifiers: modifiers)
            hotKeyManager?.onHotKeyPressed = { [weak self] in
                self?.typeClipboard()
            }
        }

        typeClipboardMenuItem?.title = "Type Clipboard (\(HotKeySettings.displayString(keyCode: UInt32(keyCode), modifiers: modifiers)))"
    }

    private func requestAccessibilityPermission() {
        guard !AXIsProcessTrusted() else { return }
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: NSDictionary = [promptKey: true]
        _ = AXIsProcessTrustedWithOptions(options)
    }

    @objc private func typeClipboard() {
        DispatchQueue.main.async { [weak self] in
            self?.clipboardTyper.typeClipboardContents()
        }
    }

    @objc private func openSettings() {
        // Use string selector to avoid compile issues on older SDKs.
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
