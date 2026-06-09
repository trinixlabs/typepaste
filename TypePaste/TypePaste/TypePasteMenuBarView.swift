//
//  TypePasteMenuBarView.swift
//  TypePaste
//
//  Created by Codex on 08/06/2026.
//

import AppKit
import SwiftUI

struct TypePasteMenuSnippetRow: Identifiable, Equatable {
    let id: UUID
    let slot: Int
    let title: String
    let shortcutHint: String?
}

struct TypePasteMenuState: Equatable {
    let clipboardShortcut: String
    let menuSnippets: [TypePasteMenuSnippetRow]

    init(clipboardShortcut: String, snippets: [Snippet], snippetAssignments: [SnippetHotKeyAssignment]) {
        let shortcutHints = Dictionary(uniqueKeysWithValues: snippetAssignments.map { assignment in
            (assignment.snippet.id, HotKeySettings.displayString(
                keyCode: UInt32(assignment.keyCode),
                modifiers: assignment.modifiers
            ))
        })

        self.clipboardShortcut = clipboardShortcut
        self.menuSnippets = SnippetLibrarySettings.normalized(snippets).enumerated().map { index, snippet in
            TypePasteMenuSnippetRow(
                id: snippet.id,
                slot: index + 1,
                title: snippet.displayTitle,
                shortcutHint: shortcutHints[snippet.id]
            )
        }
    }

    static func current() -> TypePasteMenuState {
        let snippets = SnippetLibrarySettings.load()
        let modifiers = HotKeySettings.modifiers
        return TypePasteMenuState(
            clipboardShortcut: HotKeySettings.displayString(
                keyCode: HotKeySettings.keyCode,
                modifiers: modifiers
            ),
            snippets: snippets,
            snippetAssignments: SnippetHotKeyMapping.assignments(
                snippets: snippets,
                baseModifiers: modifiers
            )
        )
    }
}

struct TypePasteMenuBarView: View {
    @Environment(\.openSettings) private var openSettings

    let appDelegate: AppDelegate

    @State private var menuState = TypePasteMenuState.current()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                appDelegate.typeClipboardFromMenuBar()
            } label: {
                menuRow(title: "Type Clipboard", shortcutHint: menuState.clipboardShortcut)
            }
            .buttonStyle(.plain)

            if !menuState.menuSnippets.isEmpty {
                Divider()
                    .padding(.vertical, 6)

                ForEach(menuState.menuSnippets) { snippet in
                    Button {
                        appDelegate.typeSnippetFromMenuBar(slot: snippet.slot)
                    } label: {
                        menuRow(title: snippet.title, shortcutHint: snippet.shortcutHint)
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()
                .padding(.vertical, 6)

            Button {
                if !SettingsWindowPositioner.bringExistingSettingsWindowToFront() {
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                }
            } label: {
                menuRow(title: "Settings…", shortcutHint: nil)
            }
            .buttonStyle(.plain)

            Button {
                appDelegate.quitFromMenuBar()
            } label: {
                menuRow(title: "Quit TypePaste", shortcutHint: nil)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .frame(width: 320)
        .onAppear {
            reloadMenuState()
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            reloadMenuState()
        }
    }

    private func reloadMenuState() {
        menuState = .current()
    }

    private func menuRow(title: String, shortcutHint: String?) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 12)

            if let shortcutHint {
                Text(shortcutHint)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
