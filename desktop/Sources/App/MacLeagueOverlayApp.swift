import SwiftUI

@main
struct MacLeagueOverlayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        print("[Hexlens] App init")
    }

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
