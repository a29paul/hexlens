import AppKit
import Carbon.HIToolbox
import os

/// Tracks enemy summoner spell cooldowns via global hotkeys.
///
/// Default hotkey layout (configurable in Settings):
///   F1 = top laner spell 1     F2 = top laner spell 2
///   F3 = jungler spell 1       F4 = jungler spell 2
///   F5 = mid laner spell 1     F6 = mid laner spell 2
///   F7 = ADC spell 1           F8 = ADC spell 2
///   F9 = support spell 1       F10 = support spell 2
///
/// When pressed, starts a cooldown timer for the corresponding enemy spell.
/// Debounces rapid presses (500ms).
class SpellTracker {
    private let logger = Logger(subsystem: "com.macleagueoverlay", category: "SpellTracker")
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var lastPressTime: [UInt16: Date] = [:]
    private let debounceInterval: TimeInterval = 0.5

    var onSpellUsed: ((Int, Int) -> Void)?  // (enemyIndex, spellIndex)

    /// Hotkey mapping: F-key code → (enemy index 0-4, spell index 0-1)
    private let hotkeyMap: [UInt16: (Int, Int)] = [
        122: (0, 0),  // F1 → enemy 0, spell 1
        120: (0, 1),  // F2 → enemy 0, spell 2
        99:  (1, 0),  // F3 → enemy 1, spell 1
        118: (1, 1),  // F4 → enemy 1, spell 2
        96:  (2, 0),  // F5 → enemy 2, spell 1
        97:  (2, 1),  // F6 → enemy 2, spell 2
        98:  (3, 0),  // F7 → enemy 3, spell 1
        100: (3, 1),  // F8 → enemy 3, spell 2
        101: (4, 0),  // F9 → enemy 4, spell 1
        109: (4, 1),  // F10 → enemy 4, spell 2
    ]

    func start() {
        // Check accessibility permission
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)

        if !trusted {
            logger.warning("Accessibility permission not granted. Hotkeys won't work until permission is given.")
            return
        }

        // Create event tap for global key events
        let eventMask = (1 << CGEventType.keyDown.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passRetained(event) }
            let tracker = Unmanaged<SpellTracker>.fromOpaque(refcon).takeUnretainedValue()
            return tracker.handleKeyEvent(proxy: proxy, type: type, event: event)
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: selfPtr
        )

        guard let eventTap = eventTap else {
            logger.error("Failed to create event tap. Check accessibility permissions.")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        logger.info("SpellTracker started with global hotkeys")
    }

    func stop() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    private func handleKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else {
            return Unmanaged.passRetained(event)
        }

        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))

        guard let (enemyIndex, spellIndex) = hotkeyMap[keyCode] else {
            return Unmanaged.passRetained(event)
        }

        // Check if LoL is the frontmost app
        guard isLoLFrontmost() else {
            return Unmanaged.passRetained(event)
        }

        // Debounce
        let now = Date()
        if let lastPress = lastPressTime[keyCode],
           now.timeIntervalSince(lastPress) < debounceInterval {
            return Unmanaged.passRetained(event)
        }
        lastPressTime[keyCode] = now

        logger.info("Spell tracked: enemy \(enemyIndex), spell \(spellIndex)")
        DispatchQueue.main.async { [weak self] in
            self?.onSpellUsed?(enemyIndex, spellIndex)
        }

        // Pass the event through (don't consume it, LoL might need it)
        return Unmanaged.passRetained(event)
    }

    private func isLoLFrontmost() -> Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return false }
        return frontApp.bundleIdentifier == "com.riotgames.LeagueofLegends.GameClient"
            || frontApp.localizedName?.contains("League") == true
    }
}
