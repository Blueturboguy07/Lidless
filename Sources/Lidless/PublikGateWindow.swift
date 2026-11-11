import AppKit
import Combine
import SwiftUI

/// The Sign in with publik window: the first window Lidless shows, before the
/// Welcome window and before the popover offers any control. `Publik.swift`
/// holds the gate itself (the screens and the wallet poll); this file draws
/// one screen at a time and hands the pressed button back.
///
/// The SwiftUI adapter from publikhq.com/sdk/publik.swift.md: draws the screen
/// as a view and returns the button pressed. When the gate cancels the screen
/// (the wallet poll saw the sign-in), the screen is cleared and nil goes back.
@MainActor final class GateModel: ObservableObject, PublikGateUI {
    @Published var screen: Publik.Screen?
    private var pick: CheckedContinuation<String?, Never>?
    func show(_ s: Publik.Screen) async -> String? {
        await withTaskCancellationHandler { await withCheckedContinuation { c in pick?.resume(returning: nil); screen = s; pick = c } }
        onCancel: { Task { @MainActor in self.press(nil) } }
    }
    func press(_ action: String?) { pick?.resume(returning: action); pick = nil; if action == nil { screen = nil } }
    nonisolated func open(_ url: URL) { Task { @MainActor in NSWorkspace.shared.open(url) } }
}

/// One gate screen: the title, the body, the note and one button per action.
struct PublikGateView: View {
    @ObservedObject var model: GateModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let screen = model.screen {
                Text(screen.title)
                    .font(.title2.weight(.semibold))
                Text(screen.body)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                if let note = screen.note {
                    Text(note)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 10) {
                    Spacer()
                    ForEach(Array(screen.buttons.enumerated()), id: \.offset) { index, button in
                        Button(button.label) { model.press(button.action) }
                            .keyboardShortcut(index == 0 ? .defaultAction : .cancelAction)
                    }
                }
                .padding(.top, 6)
            } else {
                Text("Sign in with publik")
                    .font(.title2.weight(.semibold))
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(24)
        .frame(width: 440, alignment: .leading)
    }
}

/// Hosts `PublikGateView` in a plain AppKit window, the way
/// `OnboardingController` hosts the Welcome window: Lidless is an
/// `LSUIElement` app with no Dock presence, so the window brings itself
/// forward. The close button hides the window; the popover's Sign in with
/// publik button shows it again, and the gate keeps waiting meanwhile.
@MainActor final class PublikGateWindowController: NSObject, NSWindowDelegate {
    let model = GateModel()
    private var window: NSWindow?

    func show() {
        if window == nil {
            let hosting = NSHostingController(rootView: PublikGateView(model: model))
            let gateWindow = NSWindow(contentViewController: hosting)
            gateWindow.title = "Sign in with publik"
            gateWindow.styleMask = [.titled, .closable]
            gateWindow.isReleasedWhenClosed = false
            gateWindow.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
            gateWindow.hidesOnDeactivate = false
            gateWindow.delegate = self
            gateWindow.center()
            window = gateWindow
        }
        if let window {
            AppActivation.bringToFront(window)
        }
    }

    func close() {
        window?.delegate = nil
        window?.close()
        window = nil
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
