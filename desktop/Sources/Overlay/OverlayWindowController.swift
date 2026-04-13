import AppKit
import SwiftUI

/// Manages the transparent overlay window that sits on top of LoL.
///
/// Window configuration:
///   - borderless, transparent, no shadow
///   - level: .screenSaver (above fullscreen auxiliary windows)
///   - click-through by default (ignoresMouseEvents = true)
///   - toggle interactive mode via hotkey for drag-to-reposition
///   - hides via orderOut on NSApplication.didResignActiveNotification
///   - shows via makeKeyAndOrderFront when LoL regains focus
class OverlayWindowController {
    private var window: NSWindow?
    private let gameStateManager: GameStateManager
    private(set) var isInInteractiveMode = false
    private var isTabHeld = false
    private var isGameActive = false
    private var keyDownMonitor: Any?
    private var keyUpMonitor: Any?

    init(gameStateManager: GameStateManager) {
        self.gameStateManager = gameStateManager
        createWindow()
        setupTabMonitor()
    }

    private func createWindow() {
        let overlayView = OverlayView(gameStateManager: gameStateManager)
        let hostingView = NSHostingView(rootView: overlayView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 750),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        // Use maximum window level to appear above fullscreen macOS Spaces.
        // LoL on Mac uses macOS Space-based fullscreen (not exclusive),
        // so NSWindow can appear on top with the right level + collection behavior.
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        // Overlay is interactive (clickable spell badges). The overlay is small
        // and positioned at the screen edge, so it doesn't interfere with gameplay.
        // Same approach as Porofessor/Blitz: click the spell icon to start cooldown.
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.contentView = hostingView
        // Prevent the overlay from being hidden when the app is deactivated
        window.hidesOnDeactivate = false

        // Position: top-right of main screen, inset 20px
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - 420 - 20
            let y = screenFrame.maxY - 750 - 20
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        // Restore saved position
        if let savedX = UserDefaults.standard.object(forKey: "overlayX") as? CGFloat,
           let savedY = UserDefaults.standard.object(forKey: "overlayY") as? CGFloat {
            window.setFrameOrigin(NSPoint(x: savedX, y: savedY))
        }

        self.window = window
    }

    /// Called when game becomes active. Overlay only shows when Tab is held.
    func showOverlay() {
        isGameActive = true
        // Don't show immediately. Wait for Tab press.
    }

    func hideOverlay() {
        isGameActive = false
        isTabHeld = false
        window?.orderOut(nil)
        window?.alphaValue = 0
    }

    private func setupTabMonitor() {
        // Monitor global key events for Tab (keyCode 48)
        // Tab down → show overlay, Tab up → hide overlay
        keyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 48, !event.isARepeat else { return }
            self?.handleTabDown()
        }
        keyUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyUp) { [weak self] event in
            guard event.keyCode == 48 else { return }
            self?.handleTabUp()
        }

        // Also monitor local events (when our app is frontmost, e.g. clicking overlay)
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 48, !event.isARepeat {
                self?.handleTabDown()
            }
            return event
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyUp) { [weak self] event in
            if event.keyCode == 48 {
                self?.handleTabUp()
            }
            return event
        }
    }

    private func handleTabDown() {
        guard isGameActive, !isTabHeld else { return }
        isTabHeld = true
        window?.orderFrontRegardless()
        window?.alphaValue = 0
        NSAnimationContext.runAnimationGroup { [weak self] context in
            context.duration = 0.1
            self?.window?.animator().alphaValue = 1.0
        }
    }

    private func handleTabUp() {
        guard isTabHeld else { return }
        isTabHeld = false
        NSAnimationContext.runAnimationGroup({ [weak self] context in
            context.duration = 0.1
            self?.window?.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.window?.orderOut(nil)
        })
    }

    /// Toggle drag-to-reposition mode. When active, dragging anywhere on the
    /// overlay moves it. When inactive, only spell badge clicks are intercepted.
    func toggleInteractiveMode() {
        isInInteractiveMode.toggle()

        if isInInteractiveMode {
            window?.isMovableByWindowBackground = true
        } else {
            window?.isMovableByWindowBackground = false
            // Save position when exiting drag mode
            if let frame = window?.frame {
                UserDefaults.standard.set(frame.origin.x, forKey: "overlayX")
                UserDefaults.standard.set(frame.origin.y, forKey: "overlayY")
            }
        }
    }
}
