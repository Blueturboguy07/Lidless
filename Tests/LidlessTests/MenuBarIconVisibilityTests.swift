import XCTest

/// The notch geometry of a 14" MacBook Pro at its default scaling, as reported
/// by `NSScreen.auxiliaryTopLeftArea` / `auxiliaryTopRightArea`: the housing
/// spans x 663…848 on a 1512-point-wide screen.
final class MenuBarIconVisibilityTests: XCTestCase {
    private let screen = CGRect(x: 0, y: 0, width: 1512, height: 982)
    private let notch: ClosedRange<CGFloat> = 663...848

    private func item(x: CGFloat, width: CGFloat = 36) -> CGRect {
        CGRect(x: x, y: 950, width: width, height: 32)
    }

    func testIconFullyUnderTheNotchIsHidden() {
        // The exact frame a fresh Lidless install landed on with 12 other items on the bar.
        XCTAssertEqual(MenuBarIconVisibility.evaluate(itemFrame: item(x: 754), screenFrame: screen, notchXRange: notch),
                       .hiddenBehindNotch)
    }

    func testIconClearOfTheNotchIsVisible() {
        XCTAssertEqual(MenuBarIconVisibility.evaluate(itemFrame: item(x: 873), screenFrame: screen, notchXRange: notch),
                       .visible)
        XCTAssertEqual(MenuBarIconVisibility.evaluate(itemFrame: item(x: 600), screenFrame: screen, notchXRange: notch),
                       .visible)
    }

    func testIconMostlyUnderTheNotchCountsAsHidden() {
        // 4 points peek out on the right — not enough to click.
        XCTAssertEqual(MenuBarIconVisibility.evaluate(itemFrame: item(x: 816), screenFrame: screen, notchXRange: notch),
                       .hiddenBehindNotch)
        // 12 points peek out — reachable, if ugly.
        XCTAssertEqual(MenuBarIconVisibility.evaluate(itemFrame: item(x: 824), screenFrame: screen, notchXRange: notch),
                       .visible)
    }

    func testScreenWithoutNotchIsAlwaysVisible() {
        XCTAssertEqual(MenuBarIconVisibility.evaluate(itemFrame: item(x: 754), screenFrame: screen, notchXRange: nil),
                       .visible)
    }

    func testMissingOrOffScreenFrameIsOffScreen() {
        XCTAssertEqual(MenuBarIconVisibility.evaluate(itemFrame: nil, screenFrame: screen, notchXRange: notch), .offScreen)
        XCTAssertEqual(MenuBarIconVisibility.evaluate(itemFrame: item(x: 2000), screenFrame: screen, notchXRange: notch),
                       .offScreen)
        XCTAssertEqual(MenuBarIconVisibility.evaluate(itemFrame: CGRect(x: 754, y: 950, width: 0, height: 32),
                                                      screenFrame: screen, notchXRange: notch),
                       .offScreen)
    }

    func testCombineIsReachableAnywhere() {
        XCTAssertEqual(MenuBarIconVisibility.combine([.hiddenBehindNotch, .visible]), .visible)
        XCTAssertEqual(MenuBarIconVisibility.combine([.hiddenBehindNotch, .offScreen]), .hiddenBehindNotch)
        XCTAssertEqual(MenuBarIconVisibility.combine([.offScreen]), .offScreen)
        XCTAssertEqual(MenuBarIconVisibility.combine([]), .offScreen)
    }
}
