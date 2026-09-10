import Foundation

/// Identity of the privileged helper, derived from the owning app's bundle id so
/// that Debug (`.dev`) and Release builds get fully isolated daemons/services and
/// never collide. For app bundle id `com.publikhq.lidless` the helper id —
/// which doubles as its LaunchDaemon label, Mach service name, and the `.plist`
/// basename — is `com.publikhq.lidless.helper`.
public enum LidlessHelper {
    /// Label / Mach service name for a given app bundle id.
    public static func label(appBundleID: String) -> String { "\(appBundleID).helper" }

    /// Env var the generated LaunchDaemon plist passes to the (bundle-less) helper
    /// executable so it knows which Mach service to listen on without relying on
    /// an embedded bundle id.
    public static let machLabelEnvKey = "LIDLESS_MACH_LABEL"

    /// Fallback used only if the app bundle id / env var is unavailable.
    public static let fallbackLabel = "com.publikhq.lidless.helper"

    /// The app bundle id a helper label was derived from — the inverse of
    /// `label(appBundleID:)`.
    public static func appBundleID(fromLabel label: String) -> String {
        let suffix = ".helper"
        guard label.hasSuffix(suffix) else { return label }
        return String(label.dropLast(suffix.count))
    }

    /// The Apple Developer Team ID the app and helper are signed with.
    public static let teamID = "R5R3ZS54LV"

    /// Code signing requirement the helper demands of anything connecting to it.
    ///
    /// The Mach service an `SMAppService` daemon registers is reachable by every
    /// process on the machine, and the listener used to accept all of them. So
    /// any program a user ran could ask a root daemon to hold their Mac awake
    /// indefinitely — on a laptop, in a bag, that is a heat and battery problem
    /// they'd have no way to attribute.
    ///
    /// The three clauses cover each other. `identifier` alone would admit any
    /// binary claiming the name; `anchor apple generic` alone would admit every
    /// Apple-signed app on the Mac; the team check alone would admit anything
    /// else we ever ship. Together they mean this app, signed by us.
    ///
    /// `anchor apple generic` is satisfied by Developer ID and Apple Development
    /// certificates alike, so a locally-built `.dev` app passes exactly as a
    /// released one does.
    public static func codeSigningRequirement(appBundleID: String) -> String {
        """
        identifier "\(appBundleID)" \
        and anchor apple generic \
        and certificate leaf[subject.OU] = "\(teamID)"
        """
    }
}

/// XPC interface implemented by the root helper and called by the app.
///
/// The helper runs as root (installed via `SMAppService`), so it can flip the
/// `SleepDisabled` flag without an admin prompt. A heartbeat watchdog inside the
/// helper auto-restores normal sleep if the app stops checking in — so the Mac
/// can never get stuck awake if the app crashes or is force-quit.
@objc public protocol LidlessHelperProtocol {
    /// Enable/disable lid-close sleep prevention. reply: (success, errorMessage?).
    func setKeepAwake(_ enabled: Bool, withReply reply: @escaping (Bool, String?) -> Void)

    /// Read the current SleepDisabled flag. reply: (enabled).
    func getState(withReply reply: @escaping (Bool) -> Void)

    /// Heartbeat from the app; resets the watchdog timer.
    func heartbeat(withReply reply: @escaping (Bool) -> Void)

    /// Helper version string, for a connection sanity check.
    func version(withReply reply: @escaping (String) -> Void)
}
