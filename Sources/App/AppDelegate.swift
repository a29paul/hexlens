import AppKit
import Combine
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var overlayController: OverlayWindowController?
    private var onboardingPopover: NSPopover?
    private let gameStateManager = GameStateManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Background app: no Dock icon, no Cmd-Tab entry
        NSApp.setActivationPolicy(.accessory)

        setupMenuBar()
        setupOverlay()
        setupNotifications()
        showOnboardingIfNeeded()

        gameStateManager.start()
    }

    private func showOnboardingIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") else { return }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 280)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: OnboardingView(onDismiss: { [weak self] in
                self?.onboardingPopover?.close()
                self?.onboardingPopover = nil
            })
        )
        self.onboardingPopover = popover

        // Show from menu bar button after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if let button = self?.statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "gamecontroller", accessibilityDescription: "League Overlay")
            button.image?.size = NSSize(width: 18, height: 18)
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Waiting for LoL...", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Toggle Overlay Position Mode", action: #selector(toggleOverlayMode), keyEquivalent: "p"))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Copy Debug Info", action: #selector(copyDebugInfo), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu

        // Observe state changes to update menu bar text
        gameStateManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateMenuBarForState(state)
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    private func updateMenuBarForState(_ state: GameLifecycleState) {
        let statusText: String
        switch state {
        case .idle: statusText = "Waiting for LoL..."
        case .lobby: statusText = "● In Lobby"
        case .champSelect: statusText = "● Champ Select"
        case .loading: statusText = "Loading..."
        case .inGame: statusText = "● In Game"
        case .postGame: statusText = "Game Over"
        }
        if let menu = statusItem.menu, let firstItem = menu.items.first {
            firstItem.title = statusText
        }
    }

    @objc private func toggleOverlayMode() {
        overlayController?.toggleInteractiveMode()
    }

    @objc private func copyDebugInfo() {
        let info = """
        Mac League Overlay - Debug Info
        macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)
        State: \(gameStateManager.state.rawValue)
        LoL detected: \(gameStateManager.state != .idle)
        Overlay opacity: \(UserDefaults.standard.double(forKey: "overlayOpacity"))
        LoL path: \(UserDefaults.standard.string(forKey: "lolInstallPath") ?? "default")
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(info, forType: .string)
    }

    private func setupOverlay() {
        overlayController = OverlayWindowController(gameStateManager: gameStateManager)
    }

    private func setupNotifications() {
        // Hide overlay when LoL loses focus
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )

        // Respond immediately to focus loss
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidResignActive(_:)),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    @objc private func appDidActivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        let isLoL = app.bundleIdentifier == "com.riotgames.LeagueofLegends.GameClient"
            || app.localizedName?.contains("League") == true
        if isLoL && gameStateManager.state == .inGame {
            overlayController?.showOverlay()
        }
    }

    @objc private func appDidResignActive(_ notification: Notification) {
        // Hide overlay immediately when LoL loses focus
        // This fires instantly, not after the animation
    }

    func updateMenuBarStatus(_ status: String) {
        if let menu = statusItem.menu, let firstItem = menu.items.first {
            firstItem.title = status
        }
    }
}
