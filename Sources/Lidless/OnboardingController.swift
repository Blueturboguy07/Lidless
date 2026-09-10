import AppKit
import SwiftUI

/// Hosts the first-run onboarding flow in a standalone window.
///
/// Lidless is an `LSUIElement` menu-bar app with no Dock presence, so auto-
/// presenting and focusing a window from a SwiftUI `Window` scene is unreliable.
/// A plain AppKit `NSWindow` wrapping the SwiftUI `OnboardingView` gives precise
/// control over showing, centering, focusing, and closing — and mirrors how the
/// Settings window already surfaces.
@MainActor
final class OnboardingController {
    private weak var state: AppState?
    private var window: NSWindow?

    /// The window, when it has been built — for attaching sheets to it.
    var hostWindow: NSWindow? { window }

    init(state: AppState) {
        self.state = state
    }

    /// Show the window, building it on first use and reusing it afterwards so we
    /// never stack duplicates.
    func show() {
        guard let state else { return }

        if window == nil {
            let root = OnboardingView().environmentObject(state)
            let hosting = NSHostingController(rootView: root)
            let win = NSWindow(contentViewController: hosting)
            win.title = "Welcome to Lidless"
            win.styleMask = [.titled, .closable, .fullSizeContentView]
            win.titlebarAppearsTransparent = true
            win.isMovableByWindowBackground = true
            win.isReleasedWhenClosed = false
            // Follow the user to their current Space, and don't vanish every
            // time this accessory app deactivates (which is constantly).
            win.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
            win.hidesOnDeactivate = false
            win.center()
            window = win
        }

        if let window {
            window.center()
            AppActivation.bringToFront(window)
        }
    }

    func close() {
        window?.close()
    }
}
