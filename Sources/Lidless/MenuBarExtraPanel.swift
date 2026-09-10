import AppKit

/// Dismisses the popover SwiftUI presents for `MenuBarExtra(.window)`.
///
/// SwiftUI gives a view inside that popover no way to close it: there's no
/// `isPresented` binding on `MenuBarExtra`, and the `dismiss` environment action
/// doesn't reach the panel, since the popover is its own scene (FB11984872).
///
/// So we do what the user would: click the status item. That lets SwiftUI close
/// the panel through its own path and reset its presentation state, instead of
/// leaving the menu-bar icon stuck highlighted.
///
/// Both window classes involved are private AppKit/SwiftUI types matched by
/// name, so every step degrades to doing nothing rather than crashing if those
/// internals change.
@MainActor
enum MenuBarExtraPanel {
    /// SwiftUI hosts the popover in a private `NSWindow` subclass.
    static func isPanelWindow(className: String) -> Bool {
        className.contains("MenuBarExtraWindow")
    }

    /// The status bar hosts its items in a different private subclass — one per
    /// screen when "Displays have Separate Spaces" is on.
    static func isStatusBarWindow(className: String) -> Bool {
        className.contains("NSStatusBarWindow")
    }

    /// Which window `dismiss` would fall back to closing, given the class names
    /// of the app's windows in order — or nil when none of them is the panel.
    ///
    /// Pulled out as a pure function so the selection can be tested against
    /// arbitrary window lists. The alternative is standing up real `NSWindow`s
    /// in a test, which drags in window-server availability and AppKit's
    /// release-on-close lifecycle — neither of which has anything to do with
    /// the thing worth checking, which is that only the panel is ever picked.
    static func panelWindowIndex(classNames: [String]) -> Int? {
        classNames.firstIndex { isPanelWindow(className: $0) }
    }

    /// Class names of the status-bar windows to try, in order.
    static func statusBarWindowIndices(classNames: [String]) -> [Int] {
        classNames.indices.filter { isStatusBarWindow(className: classNames[$0]) }
    }

    /// Open the popover if it's closed. No-op when it's already showing.
    ///
    /// The status item belongs to SwiftUI, which offers no API to present its
    /// panel, so this clicks the item's button the way `dismiss` does. It's how
    /// the ⌃⌥L hotkey and the "Open the Lidless menu" buttons get the menu up
    /// when the icon itself is out of reach (see `MenuBarIconMonitor`).
    static func open() {
        open(windows: NSApp.windows)
    }

    static func open(windows: [NSWindow]) {
        // Already up: leave it. (Checking the real window rather than the
        // button state, which can go stale after a dismissal we didn't drive.)
        if windows.contains(where: { isPanelWindow(className: $0.className) && $0.isVisible }) { return }

        for window in windows where isStatusBarWindow(className: window.className) {
            guard window.responds(to: NSSelectorFromString("statusItem")),
                  let item = window.value(forKey: "statusItem") as? NSStatusItem,
                  let button = item.button
            else { continue }
            button.performClick(button)
            return
        }
    }

    /// Close the popover if it's open. No-op when it isn't.
    static func dismiss() {
        dismiss(windows: NSApp.windows)
    }

    static func dismiss(windows: [NSWindow]) {
        for window in windows where isStatusBarWindow(className: window.className) {
            // `statusItem` is a private property. Ask before reading it: a bare
            // value(forKey:) raises an uncatchable ObjC exception if it's gone.
            guard window.responds(to: NSSelectorFromString("statusItem")),
                  let item = window.value(forKey: "statusItem") as? NSStatusItem,
                  let button = item.button,
                  button.state != .off  // clicking a closed popover would open it
            else { continue }

            button.performClick(button)
            button.isHighlighted = button.state != .off
            return
        }

        // If that shape ever changes, close the panel directly. The icon stays
        // highlighted until the next click, which beats a popover that won't go.
        if let index = panelWindowIndex(classNames: windows.map(\.className)) {
            windows[index].close()
        }
    }
}
