import AppKit
import Carbon.HIToolbox

/// One global hotkey through Carbon's `RegisterEventHotKey`.
///
/// Chosen over `NSEvent.addGlobalMonitorForEvents` because that needs the
/// Accessibility permission to see key presses at all; a Carbon hotkey works
/// out of the box, which is the whole point when the menu-bar icon can't be
/// reached and the shortcut is the way in.
final class HotKeyManager {
    /// Control + Option + L — "Lidless". Fixed on purpose: this is a rescue
    /// shortcut, not a feature that needs a preference.
    static let defaultKeyCode = UInt32(kVK_ANSI_L)
    static let defaultModifiers = UInt32(controlKey | optionKey)
    static let defaultDisplayName = "⌃⌥L"

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let hotKeyID: EventHotKeyID
    private let action: @MainActor () -> Void

    /// Registers immediately. `action` runs on the main actor.
    init?(keyCode: UInt32 = HotKeyManager.defaultKeyCode,
          modifiers: UInt32 = HotKeyManager.defaultModifiers,
          action: @escaping @MainActor () -> Void) {
        self.action = action
        // 'LDLS' — any four-char tag distinguishing our hotkeys from other apps'.
        hotKeyID = EventHotKeyID(signature: 0x4C44_4C53, id: 1)

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { _, event, userData in
            guard let event, let userData else { return noErr }
            var pressed = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &pressed)
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.fired(pressed)
            return noErr
        }
        let installed = InstallEventHandler(GetApplicationEventTarget(), callback, 1, &spec,
                                            Unmanaged.passUnretained(self).toOpaque(), &handlerRef)
        guard installed == noErr else { return nil }

        let registered = RegisterEventHotKey(keyCode, modifiers, hotKeyID,
                                             GetApplicationEventTarget(), 0, &hotKeyRef)
        guard registered == noErr else {
            if let handlerRef { RemoveEventHandler(handlerRef) }
            return nil
        }
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }

    private func fired(_ pressed: EventHotKeyID) {
        guard pressed.signature == hotKeyID.signature, pressed.id == hotKeyID.id else { return }
        let action = self.action
        Task { @MainActor in action() }
    }
}
