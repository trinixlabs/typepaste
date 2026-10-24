import Foundation
import Testing
@testable import TypePaste

@MainActor
struct TypingSessionControllerTests {
    @Test
    func typesUnicodeEmojiAndMultilineTextExactlyOnce() async throws {
        let keyboard = TestKeyboardTyper()
        let controller = TypingSessionController(keyboardTyper: keyboard)
        let text = "Hello\nПривет 👩🏽‍💻 e\u{301}\t!"
        controller.start(text, initialDelay: 0.001, perCharacterDelay: 0.001)

        try await waitFor { controller.state == .idle }

        #expect(keyboard.output == text)
    }

    @Test
    func stoppingDuringInitialDelayEmitsNothing() async throws {
        let keyboard = TestKeyboardTyper()
        let controller = TypingSessionController(keyboardTyper: keyboard)
        controller.start("abc", initialDelay: 0.04, perCharacterDelay: 0.001)
        #expect(controller.handleRepeatedHotkey(.stop))
        try await Task.sleep(for: .milliseconds(70))

        #expect(controller.state == .idle)
        #expect(keyboard.output.isEmpty)
        #expect(!controller.handleRepeatedHotkey(.stop))
    }

    @Test
    func stoppingBetweenCharactersInvalidatesPendingWork() async throws {
        let keyboard = TestKeyboardTyper()
        let controller = TypingSessionController(keyboardTyper: keyboard)
        controller.start("abc", initialDelay: 0.001, perCharacterDelay: 0.05)
        try await waitFor { keyboard.output == "a" }
        controller.handleRepeatedHotkey(.stop)
        try await Task.sleep(for: .milliseconds(80))

        #expect(keyboard.output == "a")
    }

    @Test
    func triplePressStartsFreshSessionAndRapidStopPressesDoNotLeak() async throws {
        let keyboard = TestKeyboardTyper()
        let controller = TypingSessionController(keyboardTyper: keyboard)
        controller.start("old", initialDelay: 0.03, perCharacterDelay: 0.001)
        controller.handleRepeatedHotkey(.stop)
        controller.start("new", initialDelay: 0.001, perCharacterDelay: 0.001)
        try await waitFor { controller.state == .idle }
        #expect(keyboard.output == "new")

        for _ in 0..<100 {
            controller.start("stale", initialDelay: 0.001, perCharacterDelay: 0.001)
            controller.handleRepeatedHotkey(.stop)
        }
        try await Task.sleep(for: .milliseconds(40))
        #expect(keyboard.output == "new")
    }

    @Test
    func pauseDuringInitialDelayRetainsTheSession() async throws {
        let keyboard = TestKeyboardTyper()
        let controller = TypingSessionController(keyboardTyper: keyboard)
        controller.start("abc", initialDelay: 0.03, perCharacterDelay: 0.001)
        controller.handleRepeatedHotkey(.pauseResume)
        try await Task.sleep(for: .milliseconds(50))
        #expect(controller.state == .paused)
        #expect(keyboard.output.isEmpty)

        controller.handleRepeatedHotkey(.pauseResume)
        try await waitFor { controller.state == .idle }
        #expect(keyboard.output == "abc")
    }

    @Test
    func pauseResumePreservesExactPositionAcrossRapidToggles() async throws {
        let keyboard = TestKeyboardTyper()
        let controller = TypingSessionController(keyboardTyper: keyboard)
        controller.start("a👩🏽‍💻\nb", initialDelay: 0.001, perCharacterDelay: 0.05)
        try await waitFor { keyboard.output == "a" }
        controller.handleRepeatedHotkey(.pauseResume)
        try await Task.sleep(for: .milliseconds(80))
        #expect(keyboard.output == "a")

        for _ in 0..<100 {
            controller.handleRepeatedHotkey(.pauseResume)
        }
        #expect(controller.state == .paused)
        controller.handleRepeatedHotkey(.pauseResume)
        try await waitFor { controller.state == .idle }
        #expect(keyboard.output == "a👩🏽‍💻\nb")
    }

    @Test
    func restartPreservesAlreadyTypedTextAndInvalidatesOldTask() async throws {
        let keyboard = TestKeyboardTyper()
        let controller = TypingSessionController(keyboardTyper: keyboard)
        controller.start("abc", initialDelay: 0.001, perCharacterDelay: 0.04)
        try await waitFor { keyboard.output == "a" }
        controller.handleRepeatedHotkey(.restart)
        try await waitFor { controller.state == .idle }
        try await Task.sleep(for: .milliseconds(60))
        #expect(keyboard.output == "aabc")
    }

    @Test
    func rapidRestartsBeforeInitialDelayProduceOnlyOneSession() async throws {
        let keyboard = TestKeyboardTyper()
        let controller = TypingSessionController(keyboardTyper: keyboard)
        controller.start("abc", initialDelay: 0.02, perCharacterDelay: 0.001)
        for _ in 0..<100 {
            controller.handleRepeatedHotkey(.restart)
        }
        try await waitFor { controller.state == .idle }
        #expect(keyboard.output == "abc")
    }

    @Test
    func switchingModesWhilePausedUsesTheNewAction() async throws {
        let keyboard = TestKeyboardTyper()
        let controller = TypingSessionController(keyboardTyper: keyboard)
        controller.start("abc", initialDelay: 0.001, perCharacterDelay: 0.04)
        try await waitFor { keyboard.output == "a" }
        controller.handleRepeatedHotkey(.pauseResume)
        controller.handleRepeatedHotkey(.restart)
        controller.handleRepeatedHotkey(.pauseResume)
        #expect(controller.state == .paused)
        controller.handleRepeatedHotkey(.stop)
        try await Task.sleep(for: .milliseconds(60))
        #expect(controller.state == .idle)
        #expect(keyboard.output == "a")
    }

    @Test
    func modifiersSuspendEmissionAndCancellationStillWorks() async throws {
        let keyboard = TestKeyboardTyper()
        keyboard.hasPressedModifiers = true
        let controller = TypingSessionController(keyboardTyper: keyboard)
        controller.start("old", initialDelay: 0.001, perCharacterDelay: 0.001)
        try await Task.sleep(for: .milliseconds(30))
        #expect(keyboard.output.isEmpty)
        controller.stop()
        keyboard.hasPressedModifiers = false
        controller.start("new", initialDelay: 0.001, perCharacterDelay: 0.001)
        try await waitFor { controller.state == .idle }
        #expect(keyboard.output == "new")
    }

    @Test
    func replacingPausedSessionWithSnippetDoesNotResumeOldText() async throws {
        let keyboard = TestKeyboardTyper()
        let controller = TypingSessionController(keyboardTyper: keyboard)
        controller.start("old", initialDelay: 0.001, perCharacterDelay: 0.04)
        try await waitFor { keyboard.output == "o" }
        controller.handleRepeatedHotkey(.pauseResume)
        controller.start("snippet", initialDelay: 0.001, perCharacterDelay: 0.001)
        try await waitFor { controller.state == .idle }
        #expect(keyboard.output == "osnippet")
    }
}
