import AppKit
import Testing
@testable import TypePaste

@MainActor
@Suite(.serialized)
struct ClipboardTyperTests {
    @Test
    func missingClipboardStringBeepsAndSkipsTyping() {
        let pasteboard = TestPasteboard(string: nil)
        let keyboardTyper = TestKeyboardTyper()
        let beeper = TestBeeper()
        let typer = ClipboardTyper(
            pasteboard: pasteboard,
            keyboardTyper: keyboardTyper,
            beeper: beeper
        )

        typer.typeClipboardContents()

        #expect(beeper.beepCount == 1)
        #expect(keyboardTyper.output.isEmpty)
    }

    @Test
    func newlineOnlyClipboardTextBeepsAndSkipsTyping() {
        let pasteboard = TestPasteboard(string: "\n\n")
        let keyboardTyper = TestKeyboardTyper()
        let beeper = TestBeeper()
        let typer = ClipboardTyper(
            pasteboard: pasteboard,
            keyboardTyper: keyboardTyper,
            beeper: beeper
        )

        typer.typeClipboardContents()

        #expect(beeper.beepCount == 1)
        #expect(keyboardTyper.output.isEmpty)
    }

    @Test
    func validClipboardTextIsTrimmedAndTyped() async throws {
        let pasteboard = TestPasteboard(string: "\nhello world\n")
        let keyboardTyper = TestKeyboardTyper()
        let beeper = TestBeeper()
        let typer = ClipboardTyper(
            pasteboard: pasteboard,
            keyboardTyper: keyboardTyper,
            beeper: beeper
        )

        typer.typeClipboardContents()

        #expect(beeper.beepCount == 0)
        try await waitFor { keyboardTyper.output == "hello world" }
    }

    @Test(arguments: RepeatedHotkeyAction.allCases)
    func repeatedHotkeyUsesCapturedTextBeforeReadingClipboard(_ action: RepeatedHotkeyAction) async throws {
        let defaults = UserDefaults.standard
        let previousAction = defaults.object(forKey: TypingSettings.repeatedHotkeyActionKey)
        defer { defaults.set(previousAction, forKey: TypingSettings.repeatedHotkeyActionKey) }
        defaults.set(action.rawValue, forKey: TypingSettings.repeatedHotkeyActionKey)
        let pasteboard = TestPasteboard(string: "abc")
        let keyboard = TestKeyboardTyper()
        let beeper = TestBeeper()
        let typer = ClipboardTyper(pasteboard: pasteboard, keyboardTyper: keyboard, beeper: beeper)
        typer.typeClipboardContents()
        try await waitFor { keyboard.output == "a" }
        pasteboard.value = nil

        typer.typeClipboardContents()
        if action == .pauseResume {
            try await Task.sleep(for: .milliseconds(80))
            #expect(keyboard.output == "a")
            typer.typeClipboardContents()
        }
        let expected = action == .stop ? "a" : action == .restart ? "aabc" : "abc"
        if action == .stop {
            try await Task.sleep(for: .milliseconds(100))
        } else {
            try await waitFor { keyboard.output == expected }
        }

        #expect(keyboard.output == expected)
        #expect(pasteboard.readCount == 1)
        #expect(beeper.beepCount == 0)
    }

    @Test
    func snippetTypingReplacesClipboardSession() async throws {
        let keyboard = TestKeyboardTyper()
        let typer = ClipboardTyper(pasteboard: TestPasteboard(string: "old"), keyboardTyper: keyboard)
        typer.typeClipboardContents()
        typer.typeText("snippet")
        try await waitFor { keyboard.output == "snippet" }
        try await Task.sleep(for: .milliseconds(80))
        #expect(keyboard.output == "snippet")
    }

    @Test
    func stopThenStartCapturesNewClipboardContents() async throws {
        let defaults = UserDefaults.standard
        let previousAction = defaults.object(forKey: TypingSettings.repeatedHotkeyActionKey)
        defer { defaults.set(previousAction, forKey: TypingSettings.repeatedHotkeyActionKey) }
        defaults.set(RepeatedHotkeyAction.stop.rawValue, forKey: TypingSettings.repeatedHotkeyActionKey)
        let pasteboard = TestPasteboard(string: "old")
        let keyboard = TestKeyboardTyper()
        let typer = ClipboardTyper(pasteboard: pasteboard, keyboardTyper: keyboard)
        typer.typeClipboardContents()
        typer.typeClipboardContents()
        pasteboard.value = "new"
        typer.typeClipboardContents()
        try await waitFor { keyboard.output == "new" }
        #expect(pasteboard.readCount == 2)
    }

}

private final class TestPasteboard: PasteboardReading {
    var value: String?
    private(set) var readCount = 0

    init(string: String?) {
        self.value = string
    }

    func string(forType type: NSPasteboard.PasteboardType) -> String? {
        readCount += 1
        return value
    }
}

private final class TestBeeper: Beeping {
    private(set) var beepCount = 0

    func beep() {
        beepCount += 1
    }
}
