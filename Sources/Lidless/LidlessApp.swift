import SwiftUI

@main
struct LidlessApp: App {
    @StateObject private var state = AppState()

    init() {
        // Anonymous usage counts (publik telemetry v1): app opened, active session.
        // Runs on its own background thread. Off with DO_NOT_TRACK=1.
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        PublikTelemetry.start(appSlug: "lidless", appVersion: version)
    }

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
