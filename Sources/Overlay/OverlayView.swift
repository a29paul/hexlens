import SwiftUI

struct OverlayView: View {
    @ObservedObject var gameStateManager: GameStateManager

    @AppStorage("overlayOpacity") private var overlayOpacity: Double = 0.75

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CSTrackerSection(
                currentCS: gameStateManager.currentCS,
                csDiff: gameStateManager.csBenchmarkDiff,
                role: gameStateManager.playerRole
            )

            JungleTimersSection(timers: gameStateManager.jungleTimers)

            SpellTrackerSection(spells: gameStateManager.enemySpells)
        }
        .padding(16)
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(overlayOpacity))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - CS Tracker

struct CSTrackerSection: View {
    let currentCS: Int
    let csDiff: Int
    let role: PlayerRole

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: role == .jungle ? "JUNGLE CS" : "CS TRACKER")

            HStack(alignment: .firstTextBaseline) {
                Text("\(currentCS)")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)

                Spacer()

                Text(csDiffText)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(csDiff >= 0 ? Color.lolGreen : Color.lolRed)
            }
        }
    }

    private var csDiffText: String {
        let sign = csDiff >= 0 ? "+" : ""
        return "\(sign)\(csDiff) vs avg"
    }
}

// MARK: - Jungle Timers

struct JungleTimersSection: View {
    let timers: [JungleTimer]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "JUNGLE TIMERS")

            ForEach(timers) { timer in
                HStack {
                    Text(timer.icon)
                        .font(.system(size: 12))
                    Text(timer.name)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.lolTextSecondary)

                    Spacer()

                    Text(timer.displayValue)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(timer.color)
                        .opacity(timer.isUrgent ? urgentPulse : 1.0)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                urgentPulse = 0.4
            }
        }
    }

    @State private var urgentPulse: Double = 1.0
}

// MARK: - Spell Tracker

struct SpellTrackerSection: View {
    let spells: [EnemySpellState]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "ENEMY SUMMONER SPELLS")

            ForEach(spells) { spell in
                HStack {
                    Text(spell.championName)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.lolTextSecondary)
                        .frame(width: 60, alignment: .leading)

                    HStack(spacing: 4) {
                        SpellBadge(spell: spell.spell1)
                        SpellBadge(spell: spell.spell2)
                    }
                }
            }
        }
    }
}

struct SpellBadge: View {
    let spell: SpellCooldownState

    var body: some View {
        Text(spell.displayText)
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .frame(width: 22, height: 22)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(spell.isReady ? Color.lolGreen : Color(white: 0.2))
            )
            .foregroundStyle(spell.isReady ? .black : Color.lolRed)
    }
}

// MARK: - Shared Components

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .medium))
            .tracking(1)
            .foregroundStyle(Color.lolTextSecondary)
    }
}

// MARK: - Color Extensions

extension Color {
    static let lolGold = Color(red: 200/255, green: 170/255, blue: 110/255)
    static let lolGreen = Color(red: 74/255, green: 222/255, blue: 128/255)
    static let lolRed = Color(red: 248/255, green: 113/255, blue: 113/255)
    static let lolYellow = Color(red: 250/255, green: 204/255, blue: 21/255)
    static let lolTextSecondary = Color(white: 0.53)
    static let lolOverlayBg = Color(red: 26/255, green: 26/255, blue: 46/255)
    static let lolChampSelectBg = Color(red: 22/255, green: 33/255, blue: 62/255)
}
