import AppKit

/// Bringing one of our windows in front of everything else.
///
/// Lidless is an `LSUIElement` app, and since macOS 14 activation is
/// cooperative: `activate(ignoringOtherApps:)` is deprecated and the system may
/// simply decline, which left the first-run Welcome window sitting behind
/// whatever the user had open — the app looked like it had launched nothing.
/// `orderFrontRegardless` puts the window in front even when activation is
/// refused, so the user can at least see it and click it (which does activate).
@MainActor
enum AppActivation {
    /// Ask for activation the way the running OS wants it asked.
    static func activateApp() {
        if #available(macOS 14, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    static func bringToFront(_ window: NSWindow) {
        activateApp()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }
}
