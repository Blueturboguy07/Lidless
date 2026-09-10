import SwiftUI

/// Tells the user their menu-bar icon is unreachable and how to get in anyway.
///
/// Shown at the end of onboarding, in Settings, and (compactly) in the popover
/// itself — that last one reads oddly, but the popover is exactly what the
/// hotkey opens, so it's where a user who found the shortcut will be looking.
struct HiddenIconNotice: View {
    @EnvironmentObject var state: AppState
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Your menu bar is full, so the Lidless icon is hidden behind the notch.",
                  systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
            Text("Press \(HotKeyManager.defaultDisplayName) anywhere to open the Lidless menu. Quit a menu-bar app you don\u{2019}t need and the icon will appear.")
                .font(compact ? .caption : .callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if !compact {
                Button("Open the Lidless menu") { state.openMenu() }
            }
        }
        .font(compact ? .caption : .callout)
        .padding(compact ? 10 : 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
    }
}
