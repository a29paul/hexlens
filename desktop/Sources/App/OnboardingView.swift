import SwiftUI

/// First-launch welcome popover shown from the menu bar.
/// Covers: auto-detection, hotkeys, borderless windowed requirement.
struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gamecontroller.fill")
                    .foregroundStyle(Color.lolGold)
                    .font(.title2)
                Text("Mac League Overlay")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 12) {
                OnboardingItem(
                    icon: "eye",
                    title: "Auto-detects LoL",
                    detail: "The overlay appears automatically when you enter a game."
                )

                OnboardingItem(
                    icon: "keyboard",
                    title: "Track enemy spells",
                    detail: "Press F1-F10 during a game to mark enemy summoner spells on cooldown."
                )

                OnboardingItem(
                    icon: "rectangle.inset.filled",
                    title: "Use borderless windowed",
                    detail: "The overlay requires LoL to run in borderless windowed mode, not fullscreen."
                )
            }

            Button("Got it") {
                hasSeenOnboarding = true
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.lolGold)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .frame(width: 320)
    }
}

struct OnboardingItem: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color.lolGold)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
