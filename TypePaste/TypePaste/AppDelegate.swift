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
    private let typingActionHandler: TypingActionHandling
    private lazy var actionPerformer = TypePasteActionPerformer(typingActionHandler: typingActionHandler)
    private var hotKeyManager: HotKeyManager?
    private var hotKeyObserver: NSObjectProtocol?

    override init() {
        self.typingActionHandler = ClipboardTyper()
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Keep launch minimal and perform setup on the next main-loop turn.
        // This avoids first-launch timing issues while macOS is presenting trust prompts.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.requestAccessibilityPermission()
            NSApp.setActivationPolicy(.accessory)
            self.setUpHotKey()
            self.observeHotKeyChanges()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager = nil
        hotKeyObserver = nil
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
            Task { @MainActor [weak self] in
                self?.updateHotKeyFromSettings()
            }
        }
    }

    private func updateHotKeyFromSettings() {
        let registrations = currentHotKeyRegistrations()

        if let hotKeyManager {
            hotKeyManager.update(registrations: registrations)
        } else {
            hotKeyManager = HotKeyManager(registrations: registrations)
            hotKeyManager?.onHotKeyPressed = { [weak self] id in
                self?.performAction(withID: id)
            }
        }
    }

    private func currentHotKeyRegistrations() -> [HotKeyRegistration] {
        let clipboardRegistration = HotKeyRegistration(
            id: HotKeyAction.clipboard.id,
            keyCode: Int(HotKeySettings.keyCode),
            modifiers: HotKeySettings.modifiers
        )

        let snippetRegistrations = SnippetHotKeyMapping.assignments(
            snippets: currentSnippets(),
            baseModifiers: HotKeySettings.modifiers
        ).map { assignment in
            HotKeyRegistration(
                id: HotKeyAction.snippet(slot: assignment.slot).id,
                keyCode: assignment.keyCode,
                modifiers: assignment.modifiers
            )
        }

        return [clipboardRegistration] + snippetRegistrations
    }

    private func currentSnippets() -> [Snippet] {
        SnippetLibrarySettings.load()
    }

    private func requestAccessibilityPermission() {
        guard !AXIsProcessTrusted() else { return }
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: NSDictionary = [promptKey: true]
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func typeClipboardFromMenuBar() {
        performAction(.clipboard)
    }

    func typeSnippetFromMenuBar(slot: Int) {
        performAction(.snippet(slot: slot))
    }

    private func performAction(withID id: UInt32) {
        guard let action = HotKeyAction(id: id) else { return }
        performAction(action)
    }

    private func performAction(_ action: HotKeyAction) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.actionPerformer.perform(action, snippets: self.currentSnippets())
        }
    }

    func quitFromMenuBar() {
        NSApp.terminate(nil)
    }
}
