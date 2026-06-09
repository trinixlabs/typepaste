//
//  ContentView.swift
//  TypePaste
//
//  Created by Tim Haselaars on 03/02/2026.
//

import AppKit
import Carbon
import OSLog
import SwiftUI

struct ContentView: View {
    private static let githubRepositoryURL = URL(string: "https://github.com/trinixlabs/TypePaste")!

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.trinix.TypePaste",
        category: "Settings"
    )

    @AppStorage(TypingSettings.initialDelayKey) private var initialDelay: Double = 0.35
    @AppStorage(TypingSettings.perCharacterDelayKey) private var perCharacterDelay: Double = 0.04
    @AppStorage(TypingSettings.recordingModeKey) private var recordingModeEnabled: Bool = false
    @AppStorage(HotKeySettings.keyCodeKey) private var hotKeyCode: Int = Int(kVK_ANSI_1)
    @AppStorage(HotKeySettings.modifiersKey) private var hotKeyModifiers: Int = Int(cmdKey)
    @State private var selectedTab: TypePasteSettingsTab = .general
    @State private var snippets: [Snippet] = SnippetLibrarySettings.load()
    @State private var selectedSnippetID: Snippet.ID?
    @State private var settingsWindow: NSWindow?

    var body: some View {
        VStack(spacing: 0) {
            settingsTabBar

            Divider()

            ScrollView {
                Group {
                    switch selectedTab {
                    case .general:
                        generalTab
                    case .snippets:
                        snippetsTab
                    case .about:
                        aboutTab
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(
            minWidth: selectedTab.preferredWindowSize.width,
            minHeight: selectedTab.preferredWindowSize.height
        )
        .background(
            SettingsWindowAccessor { window in
                if settingsWindow !== window {
                    logger.info(
                        "Resolved settings window number=\(window.windowNumber) frame=\(window.frame.debugDescription, privacy: .public)"
                    )
                    settingsWindow = window
                }
            }
        )
        .onAppear {
            if selectedSnippetID == nil {
                selectedSnippetID = snippets.first?.id
            }
            logger.info("Settings content appeared")
        }
        .onChange(of: selectedTab) { _, newTab in
            logger.info("Selected settings tab: \(newTab.title, privacy: .public)")
            resizeWindow(for: newTab)
        }
    }

    private var settingsTabBar: some View {
        HStack(spacing: 14) {
            ForEach(TypePasteSettingsTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selectedTab == tab ? Color.accentColor.opacity(0.14) : Color.clear)

                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: .regular))
                            Text(tab.title)
                                .font(.system(size: 13))
                        }
                    }
                    .frame(width: 120, height: 68)
                    .foregroundStyle(selectedTab == tab ? Color.accentColor : Color.primary)
                }
                .buttonStyle(.plain)
                .contentShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("TypePaste")
                    .font(.title2)
                Text("Use the primary shortcut to type the current clipboard contents into the active app.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Current shortcut: \(HotKeySettings.displayString(keyCode: UInt32(hotKeyCode), modifiers: sanitizedHotKeyModifiers))")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("If typing does not work, grant Accessibility permissions in System Settings > Privacy & Security > Accessibility.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 6)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Typing")

                settingsToggleRow(
                    "Recording Mode:",
                    title: "Enable recording-safe delays",
                    isOn: $recordingModeEnabled
                )

                alignedRow("Initial Delay:") {
                    delaySlider(value: $initialDelay, range: 0.05...1.5, step: 0.01)
                }

                alignedRow("Per Character:") {
                    delaySlider(value: $perCharacterDelay, range: 0.01...0.2, step: 0.005)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Hotkey")

                alignedRow("Primary Key:") {
                    Picker("Key", selection: $hotKeyCode) {
                        ForEach(HotKeySettings.availableKeys) { key in
                            Text(key.name).tag(key.keyCode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 180, alignment: .leading)
                }

                settingsToggleRow(
                    "Command:",
                    title: "Required for the primary shortcut",
                    isOn: Binding(
                        get: { true },
                        set: { _ in hotKeyModifiers = Int(sanitizedHotKeyModifiers) }
                    )
                )
                .disabled(true)

                settingsToggleRow("Option:", title: "Include Option", isOn: modifierBinding(for: UInt32(optionKey)))
                settingsToggleRow("Control:", title: "Include Control", isOn: modifierBinding(for: UInt32(controlKey)))

                settingsToggleRow(
                    "Shift:",
                    title: "Reserved for snippet shortcuts",
                    isOn: Binding(
                        get: { false },
                        set: { _ in hotKeyModifiers = Int(sanitizedHotKeyModifiers) }
                    )
                )
                .disabled(true)

                alignedRow("Snippet Pattern:") {
                    Text(snippetShortcutPattern)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var snippetsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Snippet Library")
                    .font(.title2)
                Text("The first 9 snippets appear in the menu bar and can be typed instantly with \(snippetShortcutPattern).")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 6)

            HStack(alignment: .top, spacing: 16) {
                snippetListPane

                Divider()
                    .frame(maxHeight: .infinity)

                snippetEditorPane
            }
        }
    }

    private var aboutTab: some View {
        VStack(spacing: 18) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(.top, 18)

            VStack(spacing: 6) {
                Text("TypePaste")
                    .font(.title2.weight(.semibold))
                Text(Self.aboutVersionText(shortVersion: shortVersionNumber, buildNumber: buildNumber))
                    .foregroundStyle(.secondary)
            }

            Button {
                NSWorkspace.shared.open(Self.githubRepositoryURL)
            } label: {
                Label("View on GitHub", systemImage: "link")
            }
            .buttonStyle(.bordered)

            Text("TypePaste is an open-source menu bar app for typing clipboard text into the active app with natural delays.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 340)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var snippetListPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                Text("Saved Snippets")
                    .font(.headline)

                Spacer(minLength: 8)

                Button {
                    addSnippet()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.bordered)
                .help("Add snippet")

                Button {
                    deleteSelectedSnippet()
                } label: {
                    Image(systemName: "minus")
                }
                .buttonStyle(.bordered)
                .disabled(selectedSnippet == nil)
                .help("Delete selected snippet")
            }
            .padding(.horizontal, 2)

            List(selection: $selectedSnippetID) {
                ForEach(snippets) { snippet in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(snippet.displayTitle)
                                .lineLimit(1)
                            Text(snippet.text.replacingOccurrences(of: "\n", with: " "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        if let slot = slot(for: snippet), slot <= SnippetLibrarySettings.maxHotKeySnippets {
                            Text("#\(slot)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(snippet.id)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .frame(width: 300, height: 380)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
            )

            HStack {
                Button("Move Up") { moveSelectedSnippet(offset: -1) }
                    .disabled(!canMoveSelectedSnippet(offset: -1))
                Button("Move Down") { moveSelectedSnippet(offset: 1) }
                    .disabled(!canMoveSelectedSnippet(offset: 1))
                Spacer()
            }
        }
        .frame(minWidth: 260, maxWidth: 300, maxHeight: .infinity, alignment: .topLeading)
    }

    private var shortVersionNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildNumber: String? {
        Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
    }

    static func aboutVersionText(shortVersion: String, buildNumber: String?) -> String {
        guard let buildNumber, !buildNumber.isEmpty else {
            return "Version \(shortVersion)"
        }

        return "Version \(shortVersion) (\(buildNumber))"
    }

    static func shouldAnimateResize(for tab: TypePasteSettingsTab) -> Bool {
        false
    }

    private var snippetEditorPane: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Snippet Details")
                .font(.headline)

            if selectedSnippet != nil {
                alignedEditorRow("Title:") {
                    TextField("Title", text: selectedSnippetTitleBinding)
                        .textFieldStyle(.roundedBorder)
                }

                alignedEditorRow("Text:") {
                    TextEditor(text: selectedSnippetTextBinding)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 360)
                        .padding(6)
                        .background(Color(nsColor: .textBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                        )
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select a snippet to edit")
                        .font(.headline)
                    Text("Use the menu bar or the Shift-based snippet hotkeys to trigger the first 9 entries.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func alignedRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .frame(width: 120, alignment: .trailing)
                .foregroundStyle(.secondary)
            content()
                .frame(width: 340, alignment: .leading)
        }
        .frame(width: 520, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func alignedEditorRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .frame(width: 80, alignment: .trailing)
                .foregroundStyle(.secondary)
            content()
        }
    }

    @ViewBuilder
    private func settingsToggleRow(_ label: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .trailing)
            Toggle(title, isOn: isOn)
                .toggleStyle(.checkbox)
                .frame(width: 340, alignment: .leading)
        }
        .frame(width: 520, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func delaySlider(value: Binding<Double>, range: ClosedRange<Double>, step: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Slider(value: value, in: range, step: step)
            Text("\(value.wrappedValue, specifier: "%.2f")s")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private var sanitizedHotKeyModifiers: UInt32 {
        HotKeySettings.sanitizeModifiers(UInt32(hotKeyModifiers))
    }

    private func modifierBinding(for flag: UInt32) -> Binding<Bool> {
        Binding(
            get: { (UInt32(hotKeyModifiers) & flag) != 0 },
            set: { isOn in
                var value = UInt32(hotKeyModifiers)
                if isOn {
                    value |= flag
                } else {
                    value &= ~flag
                }
                hotKeyModifiers = Int(HotKeySettings.sanitizeModifiers(value))
            }
        )
    }

    private var selectedSnippet: Snippet? {
        guard let selectedSnippetID else { return nil }
        return snippets.first(where: { $0.id == selectedSnippetID })
    }

    private var selectedSnippetTitleBinding: Binding<String> {
        Binding(
            get: { selectedSnippet?.title ?? "" },
            set: { updateSelectedSnippet(title: $0, text: selectedSnippet?.text) }
        )
    }

    private var selectedSnippetTextBinding: Binding<String> {
        Binding(
            get: { selectedSnippet?.text ?? "" },
            set: { updateSelectedSnippet(title: selectedSnippet?.title, text: $0) }
        )
    }

    private func addSnippet() {
        let snippet = Snippet(
            id: UUID(),
            title: "New Snippet",
            text: "",
            order: snippets.count
        )
        snippets.append(snippet)
        persistSnippets()
        selectedSnippetID = snippet.id
    }

    private func deleteSelectedSnippet() {
        guard let selectedSnippetID else { return }
        snippets.removeAll { $0.id == selectedSnippetID }
        persistSnippets()
        self.selectedSnippetID = snippets.first?.id
    }

    private func moveSelectedSnippet(offset: Int) {
        guard let selectedSnippetID else { return }
        guard let index = snippets.firstIndex(where: { $0.id == selectedSnippetID }) else { return }

        let newIndex = index + offset
        guard snippets.indices.contains(newIndex) else { return }

        let snippet = snippets.remove(at: index)
        snippets.insert(snippet, at: newIndex)
        persistSnippets()
        self.selectedSnippetID = selectedSnippetID
    }

    private func canMoveSelectedSnippet(offset: Int) -> Bool {
        guard let selectedSnippetID else { return false }
        guard let index = snippets.firstIndex(where: { $0.id == selectedSnippetID }) else { return false }
        return snippets.indices.contains(index + offset)
    }

    private func updateSelectedSnippet(title: String?, text: String?) {
        guard let selectedSnippetID else { return }
        guard let index = snippets.firstIndex(where: { $0.id == selectedSnippetID }) else { return }

        if let title {
            snippets[index].title = title
        }
        if let text {
            snippets[index].text = text
        }
        persistSnippets()
    }

    private func persistSnippets() {
        snippets = SnippetLibrarySettings.normalized(snippets)
        SnippetLibrarySettings.save(snippets)
    }

    private func slot(for snippet: Snippet) -> Int? {
        guard let index = snippets.firstIndex(of: snippet) else { return nil }
        return index + 1
    }

    private var snippetShortcutPattern: String {
        var preview = HotKeySettings.snippetDisplayString(
            slot: 1,
            baseModifiers: sanitizedHotKeyModifiers
        )
        if let lastCharacter = preview.last, lastCharacter == "1" {
            preview.removeLast()
            preview.append("1…9")
        }
        return preview
    }

    private func resizeWindow(for tab: TypePasteSettingsTab) {
        DispatchQueue.main.async {
            guard let window = settingsWindow else {
                logger.error("Cannot resize settings window for tab \(tab.title, privacy: .public): no resolved window")
                return
            }

            let visibleFrame = SettingsWindowPositioner.visibleFrame(for: window)
            let targetFrame = SettingsWindowPositioner.resizedFrame(
                from: window.frame,
                visibleFrame: visibleFrame,
                targetSize: tab.preferredWindowSize
            )

            logger.info(
                """
                Resizing settings window for tab \(tab.title, privacy: .public); \
                current=\(window.frame.debugDescription, privacy: .public) \
                target=\(targetFrame.debugDescription, privacy: .public) \
                visible=\(visibleFrame.debugDescription, privacy: .public)
                """
            )

            window.setFrame(
                targetFrame,
                display: true,
                animate: Self.shouldAnimateResize(for: tab)
            )
        }
    }
}
