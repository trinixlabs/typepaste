import Foundation
import Testing
@testable import TypePaste

@MainActor
final class TestKeyboardTyper: KeyboardTyping {
    var hasPressedModifiers = false
    private(set) var output = ""

    func typeCharacter(_ character: Character) {
        output.append(character)
    }
}

@MainActor
func waitFor(_ condition: () -> Bool) async throws {
    let deadline = ContinuousClock.now + .seconds(3)
    while !condition(), ContinuousClock.now < deadline {
        try await Task.sleep(for: .milliseconds(1))
    }
    #expect(condition())
}
