import Foundation

@MainActor
final class TypingSessionController {
    enum State {
        case idle
        case typing
        case paused
    }

    private struct Session {
        let text: [Character]
        let initialDelay: TimeInterval
        let perCharacterDelay: TimeInterval
        var position = 0
    }

    private let keyboardTyper: KeyboardTyping
    private var session: Session?
    private var task: Task<Void, Error>?
    private(set) var state: State = .idle

    init(keyboardTyper: KeyboardTyping) {
        self.keyboardTyper = keyboardTyper
    }

    func start(_ text: String, initialDelay: TimeInterval, perCharacterDelay: TimeInterval) {
        stop()
        guard !text.isEmpty else { return }
        session = Session(text: Array(text), initialDelay: initialDelay, perCharacterDelay: perCharacterDelay)
        state = .typing
        scheduleTyping()
    }

    @discardableResult
    func handleRepeatedHotkey(_ action: RepeatedHotkeyAction) -> Bool {
        guard state != .idle else { return false }
        switch action {
        case .stop:
            handleStopMode()
        case .pauseResume:
            handlePauseResumeMode()
        case .restart:
            handleRestartMode()
        }
        return true
    }

    func stop() {
        task?.cancel()
        task = nil
        session = nil
        state = .idle
    }

    private func handleStopMode() {
        stop()
    }

    private func handlePauseResumeMode() {
        if state == .paused {
            state = .typing
            scheduleTyping()
        } else {
            task?.cancel()
            task = nil
            state = .paused
        }
    }

    private func handleRestartMode() {
        task?.cancel()
        session?.position = 0
        state = .typing
        scheduleTyping()
    }

    private func scheduleTyping() {
        guard let session else { return }
        let delay = session.position == 0 ? session.initialDelay : session.perCharacterDelay
        task = Task { @MainActor [weak self] in
            try await Task.sleep(for: .seconds(delay))
            while !Task.isCancelled {
                guard let self else { return }
                if self.keyboardTyper.hasPressedModifiers {
                    try await Task.sleep(for: .milliseconds(10))
                    continue
                }
                self.emitNextCharacter()
                return
            }
        }
    }

    private func emitNextCharacter() {
        guard state == .typing, var session else { return }
        keyboardTyper.typeCharacter(session.text[session.position])
        session.position += 1
        if session.position == session.text.count {
            stop()
        } else {
            self.session = session
            scheduleTyping()
        }
    }
}
