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

    init(gameStateManager: GameStateManager) {
        self.gameStateManager = gameStateManager
        createWindow()
    }

    private func createWindow() {
        let overlayView = OverlayView(gameStateManager: gameStateManager)
        let hostingView = NSHostingView(rootView: overlayView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 400),
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
        window.ignoresMouseEvents = true
        window.contentView = hostingView
        // Prevent the overlay from being hidden when the app is deactivated
        window.hidesOnDeactivate = false

        // Position: top-right of main screen, inset 20px
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - 280 - 20
            let y = screenFrame.maxY - 400 - 20
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        // Restore saved position
        if let savedX = UserDefaults.standard.object(forKey: "overlayX") as? CGFloat,
           let savedY = UserDefaults.standard.object(forKey: "overlayY") as? CGFloat {
            window.setFrameOrigin(NSPoint(x: savedX, y: savedY))
        }

        self.window = window
    }

    func showOverlay() {
        window?.orderFrontRegardless()
        window?.alphaValue = 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window?.animator().alphaValue = 1.0
        }
    }

    func hideOverlay() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            window?.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.window?.orderOut(nil)
        })
    }

    func toggleInteractiveMode() {
        isInInteractiveMode.toggle()
        window?.ignoresMouseEvents = !isInInteractiveMode

        if isInInteractiveMode {
            window?.isMovableByWindowBackground = true
        } else {
            window?.isMovableByWindowBackground = false
            // Save position when exiting interactive mode
            if let frame = window?.frame {
                UserDefaults.standard.set(frame.origin.x, forKey: "overlayX")
                UserDefaults.standard.set(frame.origin.y, forKey: "overlayY")
            }
        }
    }
}
