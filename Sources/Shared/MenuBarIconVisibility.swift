import CoreGraphics

/// Whether a menu-bar status item can actually be reached by the pointer.
///
/// macOS lays status items out from the right edge of the menu bar, so on a
/// crowded bar the newest item — a freshly installed app's — is the leftmost.
/// On a MacBook with a camera housing (the "notch") that slot can sit *behind*
/// the housing: the item exists, accessibility can press it, but no click can
/// reach it, so to the user the app has no menu. Pure geometry so it can be
/// unit-tested without AppKit; `MenuBarIconMonitor` feeds it real frames.
public enum MenuBarIconVisibility: Equatable {
    case visible
    /// The item's clickable width lies (almost) entirely under the camera housing.
    case hiddenBehindNotch
    /// The item has no on-screen frame at all: no status bar window yet, or a
    /// frame outside every screen.
    case offScreen

    /// Minimum visible width, in points, for an icon to count as clickable.
    public static let minimumClickableWidth: CGFloat = 8

    /// - Parameters:
    ///   - itemFrame: the status item's frame, in the same coordinate space as
    ///     `screenFrame` (nil when the item has no window).
    ///   - screenFrame: the frame of the screen the item is on.
    ///   - notchXRange: the horizontal extent of that screen's camera housing,
    ///     nil when the screen has none.
    public static func evaluate(itemFrame: CGRect?,
                                screenFrame: CGRect,
                                notchXRange: ClosedRange<CGFloat>?) -> MenuBarIconVisibility {
        guard let itemFrame, itemFrame.width > 0, screenFrame.intersects(itemFrame) else {
            return .offScreen
        }
        guard let notch = notchXRange, notch.upperBound > notch.lowerBound else { return .visible }
        let notchBand = CGRect(x: notch.lowerBound, y: itemFrame.minY,
                               width: notch.upperBound - notch.lowerBound, height: itemFrame.height)
        let covered = itemFrame.intersection(notchBand)
        let visibleWidth = itemFrame.width - (covered.isNull ? 0 : covered.width)
        return visibleWidth < minimumClickableWidth ? .hiddenBehindNotch : .visible
    }

    /// Overall verdict across every screen the item appears on: it's reachable
    /// if it's reachable anywhere.
    public static func combine(_ verdicts: [MenuBarIconVisibility]) -> MenuBarIconVisibility {
        if verdicts.contains(.visible) { return .visible }
        if verdicts.contains(.hiddenBehindNotch) { return .hiddenBehindNotch }
        return .offScreen
    }
}
