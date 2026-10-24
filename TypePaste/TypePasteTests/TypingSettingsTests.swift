import Foundation
import Testing
@testable import TypePaste

@Suite(.serialized)
struct TypingSettingsTests {
    @Test
    func defaultValuesAreUsedWhenSettingsAreMissing() {
        let defaults = UserDefaults.standard
        resetTypingSettings(in: defaults)
        defer { resetTypingSettings(in: defaults) }

        #expect(TypingSettings.initialDelay == 0.35)
        #expect(TypingSettings.delayPerCharacter == 0.04)
        #expect(TypingSettings.isRecordingModeEnabled == false)
    }

    @Test
    func recordingModeRaisesDelaysToMinimumRecordingThresholds() {
        let defaults = UserDefaults.standard
        resetTypingSettings(in: defaults)
        defer { resetTypingSettings(in: defaults) }
        defaults.set(0.1, forKey: TypingSettings.initialDelayKey)
        defaults.set(0.02, forKey: TypingSettings.perCharacterDelayKey)
        defaults.set(true, forKey: TypingSettings.recordingModeKey)

        #expect(TypingSettings.initialDelay == 0.7)
        #expect(TypingSettings.delayPerCharacter == 0.05)
    }

    @Test
    func explicitValuesAboveRecordingThresholdArePreserved() {
        let defaults = UserDefaults.standard
        resetTypingSettings(in: defaults)
        defer { resetTypingSettings(in: defaults) }
        defaults.set(1.2, forKey: TypingSettings.initialDelayKey)
        defaults.set(0.08, forKey: TypingSettings.perCharacterDelayKey)
        defaults.set(true, forKey: TypingSettings.recordingModeKey)

        #expect(TypingSettings.initialDelay == 1.2)
        #expect(TypingSettings.delayPerCharacter == 0.08)
    }

    @Test
    func repeatedHotkeyActionDefaultsToStopWithoutChangingExistingSettings() throws {
        let name = "TypePasteTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(0.12, forKey: TypingSettings.perCharacterDelayKey)
        defaults.set(true, forKey: TypingSettings.recordingModeKey)

        #expect(TypingSettings.repeatedHotkeyAction(in: defaults) == .stop)
        #expect(defaults.double(forKey: TypingSettings.perCharacterDelayKey) == 0.12)
        #expect(defaults.bool(forKey: TypingSettings.recordingModeKey))
    }

    @Test(arguments: RepeatedHotkeyAction.allCases)
    func repeatedHotkeyActionPersistsAcrossDefaultsInstances(_ action: RepeatedHotkeyAction) throws {
        let name = "TypePasteTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(action.rawValue, forKey: TypingSettings.repeatedHotkeyActionKey)
        #expect(defaults.synchronize())
        let restoredDefaults = try #require(UserDefaults(suiteName: name))

        #expect(TypingSettings.repeatedHotkeyAction(in: restoredDefaults) == action)
    }

    @Test
    func unknownRepeatedHotkeyActionUsesStop() throws {
        let name = "TypePasteTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set("unknown", forKey: TypingSettings.repeatedHotkeyActionKey)
        #expect(TypingSettings.repeatedHotkeyAction(in: defaults) == .stop)
    }

    private func resetTypingSettings(in defaults: UserDefaults) {
        defaults.removeObject(forKey: TypingSettings.initialDelayKey)
        defaults.removeObject(forKey: TypingSettings.perCharacterDelayKey)
        defaults.removeObject(forKey: TypingSettings.recordingModeKey)
    }
}
