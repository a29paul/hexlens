import SwiftUI

struct OverlayView: View {
    @ObservedObject var gameStateManager: GameStateManager

    @AppStorage("overlayOpacity") private var overlayOpacity: Double = 0.75

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Player stats
            PlayerStatsSection(gameStateManager: gameStateManager)

            // Gold scoreboard
            GoldScoreboard(
                allyTeamGold: gameStateManager.allyTeamGold,
                enemyTeamGold: gameStateManager.enemyTeamGold,
                matchups: gameStateManager.laneMatchups
            )

            // Enemy spells + ults
            SpellTrackerSection(gameStateManager: gameStateManager)
        }
        .padding(24)
        .frame(width: 420)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(overlayOpacity))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - CS Tracker

struct PlayerStatsSection: View {
    @ObservedObject var gameStateManager: GameStateManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // KDA header
            HStack(alignment: .firstTextBaseline) {
                Text("\(gameStateManager.kda.kills)/\(gameStateManager.kda.deaths)/\(gameStateManager.kda.assists)")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)

                Spacer()

                Text("Lv\(gameStateManager.playerLevel)")
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.lolGold)
            }

            // Stats grid
            HStack(spacing: 16) {
                StatItem(
                    label: "CS/min",
                    value: String(format: "%.1f", gameStateManager.csPerMin),
                    sub: "\(gameStateManager.currentCS) cs"
                )
                StatItem(
                    label: "Gold/min",
                    value: String(format: "%.0f", gameStateManager.goldPerMin),
                    sub: nil
                )
                StatItem(
                    label: "KP",
                    value: String(format: "%.0f%%", gameStateManager.killParticipation),
                    sub: nil
                )
                StatItem(
                    label: "Vision/min",
                    value: String(format: "%.1f", gameStateManager.visionPerMin),
                    sub: nil
                )
            }
        }
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let sub: String?

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.lolTextSecondary)
            if let sub = sub {
                Text(sub)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.lolTextSecondary.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Spell Tracker

struct SpellTrackerSection: View {
    @ObservedObject var gameStateManager: GameStateManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "ENEMY SPELLS (click to track)")

            ForEach(Array(gameStateManager.enemySpells.enumerated()), id: \.element.id) { index, enemy in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(enemy.championName.prefix(10))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                        Text("Lv\(enemy.level)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.lolTextSecondary)
                    }
                    .frame(width: 100, alignment: .leading)

                    Spacer()

                    SpellBadge(spell: enemy.ult, label: "R", size: .large) {
                        gameStateManager.markUltUsed(enemyIndex: index)
                    }

                    SpellBadge(spell: enemy.spell1, label: nil, size: .medium) {
                        gameStateManager.markSpellUsed(enemyIndex: index, spellIndex: 0)
                    }
                    SpellBadge(spell: enemy.spell2, label: nil, size: .medium) {
                        gameStateManager.markSpellUsed(enemyIndex: index, spellIndex: 1)
                    }
                }
            }
        }
    }
}

struct SpellBadge: View {
    let spell: SpellCooldownState
    var label: String?
    var size: BadgeSize = .medium
    let onTap: () -> Void

    enum BadgeSize {
        case small, medium, large
        var dimension: CGFloat {
            switch self {
            case .small: return 28
            case .medium: return 34
            case .large: return 38
            }
        }
        var fontSize: CGFloat {
            switch self {
            case .small: return 11
            case .medium: return 13
            case .large: return 15
            }
        }
    }

    var body: some View {
        Button(action: onTap) {
            Text(displayText)
                .font(.system(size: size.fontSize, weight: .bold, design: .monospaced))
                .frame(width: size.dimension, height: size.dimension)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(backgroundColor)
                )
                .foregroundStyle(foregroundColor)
        }
        .buttonStyle(.plain)
    }

    private var displayText: String {
        if spell.isReady { return label ?? "✓" }
        guard let end = spell.cooldownEnd else { return label ?? "✓" }
        let remaining = Int(end.timeIntervalSinceNow)
        if remaining <= 0 { return label ?? "✓" }
        return "\(remaining)"
    }

    private var backgroundColor: Color {
        if spell.isReady {
            return label == "R" ? Color.lolGold.opacity(0.9) : Color.lolGreen
        }
        return Color(white: 0.15)
    }

    private var foregroundColor: Color {
        spell.isReady ? .black : Color.lolRed
    }
}

// MARK: - Ally Tracker

struct AllyTrackerSection: View {
    let allies: [AllyState]

    var body: some View {
        if !allies.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "TEAM")

                ForEach(allies) { ally in
                    HStack(spacing: 8) {
                        Text(ally.championName.prefix(10))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(ally.isDead ? Color.lolRed.opacity(0.5) : .white.opacity(0.7))
                            .frame(width: 90, alignment: .leading)

                        // Ult indicator
                        Text(ally.ultReady ? "R" : "·")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .frame(width: 22, height: 22)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(ally.ultReady ? Color.lolGreen.opacity(0.8) : Color(white: 0.15))
                            )
                            .foregroundStyle(ally.ultReady ? .black : Color(white: 0.3))

                        Text("Lv\(ally.level)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.lolTextSecondary)

                        Spacer()

                        if ally.isDead {
                            Text("DEAD")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.lolRed)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Gold Scoreboard

struct GoldScoreboard: View {
    let allyTeamGold: Int
    let enemyTeamGold: Int
    let matchups: [LaneMatchup]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "GOLD")

            // Team totals
            HStack {
                Text("Your team")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.lolGreen.opacity(0.8))
                Spacer()
                Text(formatGold(allyTeamGold))
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("vs")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.lolTextSecondary)
                Text(formatGold(enemyTeamGold))
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Spacer()
                Text("Enemy")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.lolRed.opacity(0.8))
            }

            // Total diff
            let totalDiff = allyTeamGold - enemyTeamGold
            HStack {
                Spacer()
                Text(diffText(totalDiff))
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(totalDiff >= 0 ? Color.lolGold : Color.lolRed)
                Spacer()
            }

            // Lane matchups
            if !matchups.isEmpty {
                Divider().background(Color.white.opacity(0.06))

                ForEach(matchups) { lane in
                    HStack(spacing: 4) {
                        Text(positionEmoji(lane.position))
                            .font(.system(size: 12))
                            .frame(width: 18)

                        Text(lane.allyChampion.prefix(8))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 70, alignment: .leading)

                        Text(formatGold(lane.allyGold))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(Color.lolTextSecondary)
                            .frame(width: 45, alignment: .trailing)

                        Spacer()

                        Text(lane.diffText)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(lane.diff >= 0 ? Color.lolGreen : Color.lolRed)
                            .frame(width: 50)

                        Spacer()

                        Text(formatGold(lane.enemyGold))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(Color.lolTextSecondary)
                            .frame(width: 45, alignment: .leading)

                        Text(lane.enemyChampion.prefix(8))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 70, alignment: .trailing)
                    }
                }
            }
        }
    }

    private func formatGold(_ gold: Int) -> String {
        if gold >= 1000 {
            return String(format: "%.1fk", Double(gold) / 1000.0)
        }
        return "\(gold)"
    }

    private func diffText(_ diff: Int) -> String {
        let sign = diff >= 0 ? "+" : ""
        if abs(diff) >= 1000 {
            return String(format: "%@%.1fk gold", sign, Double(diff) / 1000.0)
        }
        return "\(sign)\(diff) gold"
    }

    private func positionEmoji(_ pos: String) -> String {
        switch pos {
        case "TOP": return "🗡"
        case "JUNGLE": return "🌿"
        case "MIDDLE": return "⭐"
        case "BOTTOM": return "🏹"
        case "UTILITY": return "🛡"
        default: return "•"
        }
    }
}

// MARK: - Shared Components

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .tracking(1.2)
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
