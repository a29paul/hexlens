import Foundation

/// Game lifecycle states
///
///   IDLE → LOBBY → CHAMP_SELECT → LOADING → IN_GAME → POST_GAME → IDLE
///                        │                      │
///                        └─ dodge ─→ LOBBY       └─ crash ─→ IDLE
enum GameLifecycleState: String {
    case idle
    case lobby
    case champSelect
    case loading
    case inGame
    case postGame
}

enum PlayerRole: String, Codable {
    case top, jungle, mid, adc, support, unknown
}

struct JungleTimer: Identifiable {
    let id: String
    let name: String
    let icon: String
    var respawnTime: Date?
    var isAlive: Bool

    var displayValue: String {
        guard let respawn = respawnTime else { return isAlive ? "UP" : "???" }
        let remaining = respawn.timeIntervalSinceNow
        if remaining <= 0 { return "UP" }
        let mins = Int(remaining) / 60
        let secs = Int(remaining) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var isUrgent: Bool {
        guard let respawn = respawnTime else { return false }
        return respawn.timeIntervalSinceNow > 0 && respawn.timeIntervalSinceNow < 30
    }

    var color: SwiftUI.Color {
        if isAlive { return .lolYellow }
        if isUrgent { return .lolRed }
        return SwiftUI.Color(white: 0.53)
    }
}

struct EnemySpellState: Identifiable {
    let id: String
    let championName: String
    var spell1: SpellCooldownState
    var spell2: SpellCooldownState
    var ult: SpellCooldownState
    var level: Int
}

struct SpellCooldownState {
    var spellName: String
    var rawDisplayName: String?  // for icon lookup from Data Dragon
    var cooldownEnd: Date?
    var baseCooldown: TimeInterval

    var isReady: Bool {
        guard let end = cooldownEnd else { return true }
        return Date() >= end
    }

    var displayText: String {
        if isReady { return "✓" }
        guard let end = cooldownEnd else { return "✓" }
        let remaining = Int(end.timeIntervalSinceNow)
        if remaining <= 0 { return "✓" }
        return "\(remaining)s"
    }
}

// MARK: - Ally Tracking

struct AllyState: Identifiable {
    let id: String
    let championName: String
    let summonerName: String
    var level: Int
    var isDead: Bool
    var respawnTimer: Double?
    var ultReady: Bool  // estimated from level (ult at 6+)
    var spell1Name: String
    var spell2Name: String
    var currentGold: Int?
}

// MARK: - Gold Scoreboard

struct PlayerGold: Identifiable {
    let id: String
    let championName: String
    let position: String
    let team: String
    var itemGold: Int
    var level: Int
    var isDead: Bool
}

struct LaneMatchup: Identifiable {
    let id: String  // position
    let position: String
    let allyChampion: String
    let enemyChampion: String
    var allyGold: Int
    var enemyGold: Int

    var diff: Int { allyGold - enemyGold }
    var diffText: String {
        let sign = diff >= 0 ? "+" : ""
        if abs(diff) >= 1000 {
            return String(format: "%@%.1fk", sign, Double(diff) / 1000.0)
        }
        return "\(sign)\(diff)"
    }
}

// MARK: - Inhibitor Tracking

struct InhibitorTimer: Identifiable {
    let id: String
    let lane: String  // "top", "mid", "bot"
    let team: String  // "ORDER" or "CHAOS"
    var respawnTime: Date?

    var displayValue: String {
        guard let respawn = respawnTime else { return "DOWN" }
        let remaining = respawn.timeIntervalSinceNow
        if remaining <= 0 { return "UP" }
        let mins = Int(remaining) / 60
        let secs = Int(remaining) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var isAlive: Bool {
        guard let respawn = respawnTime else { return false }
        return Date() >= respawn
    }
}

import SwiftUI

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
