import AppKit

/// Reads where SwiftUI put our `MenuBarExtra` status item and asks
/// `MenuBarIconVisibility` whether a pointer can reach it.
///
/// The status bar hosts each item in a private `NSStatusBarWindow` (one per
/// screen), so the item's frame is simply that window's frame. Matching by
/// class name is the same degrade-to-nothing approach `MenuBarExtraPanel` uses.
@MainActor
enum MenuBarIconMonitor {
    static func currentVisibility(windows: [NSWindow] = NSApp.windows,
                                  screens: [NSScreen] = NSScreen.screens) -> MenuBarIconVisibility {
        let itemFrames = windows
            .filter { MenuBarExtraPanel.isStatusBarWindow(className: $0.className) }
            .map(\.frame)
        guard !itemFrames.isEmpty else { return .offScreen }

        let verdicts = itemFrames.map { frame -> MenuBarIconVisibility in
            guard let screen = screens.first(where: { $0.frame.intersects(frame) }) else { return .offScreen }
            return MenuBarIconVisibility.evaluate(itemFrame: frame,
                                                  screenFrame: screen.frame,
                                                  notchXRange: notchXRange(of: screen))
        }
        return MenuBarIconVisibility.combine(verdicts)
    }

    /// The horizontal extent of the camera housing on `screen`, in the same
    /// coordinate space as `screen.frame`; nil for screens without one.
    static func notchXRange(of screen: NSScreen) -> ClosedRange<CGFloat>? {
        guard #available(macOS 12, *),
              let left = screen.auxiliaryTopLeftArea,
              let right = screen.auxiliaryTopRightArea,
              right.minX > left.maxX
        else { return nil }
        // The auxiliary areas are reported relative to the screen's own origin.
        // For the main screen that is also global; for a notched display placed
        // elsewhere in the arrangement, shift them into the global space the
        // window frames use.
        let offset = left.minX == 0 ? screen.frame.minX : 0
        return (left.maxX + offset)...(right.minX + offset)
    }
}
