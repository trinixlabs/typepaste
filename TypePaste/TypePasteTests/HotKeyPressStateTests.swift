import Testing
@testable import TypePaste

struct HotKeyPressStateTests {
    @Test
    func heldHotkeyTriggersOnlyOnceUntilReleased() {
        var state = HotKeyPressState()
        let firstPress = state.handle(id: 1, isPressed: true)
        #expect(firstPress)
        for _ in 0..<100 {
            let repeatedPress = state.handle(id: 1, isPressed: true)
            #expect(!repeatedPress)
        }
        let release = state.handle(id: 1, isPressed: false)
        #expect(!release)
        let nextPress = state.handle(id: 1, isPressed: true)
        #expect(nextPress)
    }

    @Test
    func primaryAndSnippetKeysHaveIndependentPressState() {
        var state = HotKeyPressState()
        let primaryPress = state.handle(id: HotKeyAction.clipboard.id, isPressed: true)
        #expect(primaryPress)
        let snippetPress = state.handle(id: HotKeyAction.snippet(slot: 2).id, isPressed: true)
        #expect(snippetPress)
        let repeatedPrimaryPress = state.handle(id: HotKeyAction.clipboard.id, isPressed: true)
        #expect(!repeatedPrimaryPress)
        let snippetRelease = state.handle(id: HotKeyAction.snippet(slot: 2).id, isPressed: false)
        #expect(!snippetRelease)
        let nextSnippetPress = state.handle(id: HotKeyAction.snippet(slot: 2).id, isPressed: true)
        #expect(nextSnippetPress)
    }
}
