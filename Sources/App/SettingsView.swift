import SwiftUI

struct SettingsView: View {
    @AppStorage("overlayOpacity") private var overlayOpacity: Double = 0.75
    @AppStorage("lolInstallPath") private var lolInstallPath: String = "/Applications/League of Legends.app"

    var body: some View {
        TabView {
            GeneralSettingsView(overlayOpacity: $overlayOpacity, lolInstallPath: $lolInstallPath)
                .tabItem { Label("General", systemImage: "gear") }

            HotkeySettingsView()
                .tabItem { Label("Hotkeys", systemImage: "keyboard") }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    @Binding var overlayOpacity: Double
    @Binding var lolInstallPath: String

    var body: some View {
        Form {
            Section("Overlay") {
                HStack {
                    Text("Opacity")
                    Slider(value: $overlayOpacity, in: 0.3...1.0, step: 0.05)
                    Text("\(Int(overlayOpacity * 100))%")
                        .monospacedDigit()
                        .frame(width: 40)
                }
            }

            Section("League of Legends") {
                HStack {
                    TextField("Install path", text: $lolInstallPath)
                    Button("Browse...") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = true
                        panel.allowedContentTypes = [.application]
                        if panel.runModal() == .OK, let url = panel.url {
                            lolInstallPath = url.path
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct HotkeySettingsView: View {
    var body: some View {
        Form {
            Section("Spell Tracking Hotkeys") {
                Text("Configure hotkeys for tracking enemy summoner spells.")
                    .foregroundStyle(.secondary)
                Text("Coming soon")
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
    }
}
