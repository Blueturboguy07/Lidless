import SwiftUI

@main
struct LidlessApp: App {
    // `AppState` runs Sign in with publik first (Sources/Lidless/Publik.swift):
    // the gate window opens before the Welcome window, the popover offers no
    // control until the person is signed in, and the same module then counts
    // usage (app opened, active session). Off with DO_NOT_TRACK=1.
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuContent()
                .environmentObject(state)
        } label: {
            Image(state.isEnabled ? "MenubarLaptopActive" : "MenubarLaptop")
        }
        .menuBarExtraStyle(.window)
        // No `Settings` scene: it doesn't reliably surface in an LSUIElement app
        // (issue #22). `AppState.showSettings()` presents it via AppKit instead.
    }
}
