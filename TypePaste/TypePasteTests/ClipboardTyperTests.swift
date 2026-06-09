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
        let workQueue = ImmediateWorkQueue()
        let typer = ClipboardTyper(
            pasteboard: pasteboard,
            keyboardTyper: keyboardTyper,
            beeper: beeper,
            workQueue: workQueue
        )

        typer.typeClipboardContents()

        #expect(beeper.beepCount == 1)
        #expect(keyboardTyper.typedTexts.isEmpty)
    }

    @Test
    func newlineOnlyClipboardTextBeepsAndSkipsTyping() {
        let pasteboard = TestPasteboard(string: "\n\n")
        let keyboardTyper = TestKeyboardTyper()
        let beeper = TestBeeper()
        let workQueue = ImmediateWorkQueue()
        let typer = ClipboardTyper(
            pasteboard: pasteboard,
            keyboardTyper: keyboardTyper,
            beeper: beeper,
            workQueue: workQueue
        )

        typer.typeClipboardContents()

        #expect(beeper.beepCount == 1)
        #expect(keyboardTyper.typedTexts.isEmpty)
    }

    @Test
    func validClipboardTextIsTrimmedAndTyped() {
        let pasteboard = TestPasteboard(string: "\nhello world\n")
        let keyboardTyper = TestKeyboardTyper()
        let beeper = TestBeeper()
        let workQueue = ImmediateWorkQueue()
        let typer = ClipboardTyper(
            pasteboard: pasteboard,
            keyboardTyper: keyboardTyper,
            beeper: beeper,
            workQueue: workQueue
        )

        typer.typeClipboardContents()

        #expect(beeper.beepCount == 0)
        #expect(keyboardTyper.typedTexts == ["hello world"])
    }
}

private final class TestPasteboard: PasteboardReading {
    private let value: String?

    init(string: String?) {
        self.value = string
    }

    func string(forType type: NSPasteboard.PasteboardType) -> String? {
        value
    }
}

private final class TestKeyboardTyper: KeyboardTyping {
    private(set) var typedTexts: [String] = []

    func typeText(_ text: String) {
        typedTexts.append(text)
    }
}

private final class TestBeeper: Beeping {
    private(set) var beepCount = 0

    func beep() {
        beepCount += 1
    }
}

private struct ImmediateWorkQueue: WorkQueueing {
    func async(_ operation: @escaping @Sendable () -> Void) {
        operation()
    }
}
