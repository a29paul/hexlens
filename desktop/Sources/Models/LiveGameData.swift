import Foundation

/// Models for the Live Client Data API (https://127.0.0.1:2999/liveclientdata/)
/// Reference: https://developer.riotgames.com/docs/lol#game-client-api

struct LiveGameAllData: Codable {
    let activePlayer: ActivePlayer
    let allPlayers: [LivePlayer]
    let events: LiveEvents
    let gameData: LiveGameInfo
}

struct ActivePlayer: Codable {
    let championStats: ChampionStats?
    let currentGold: Double
    let level: Int
    let summonerName: String

    struct ChampionStats: Codable {
        let attackDamage: Double?
        let abilityPower: Double?
        let armor: Double?
        let magicResist: Double?
    }
}

struct LivePlayer: Codable {
    let championName: String
    let isBot: Bool
    let isDead: Bool
    let items: [PlayerItem]?
    let level: Int
    let position: String
    let respawnTimer: Double?
    let scores: PlayerScores
    let skinID: Int
    let summonerName: String
    let summonerSpells: SummonerSpells
    let team: String

    struct PlayerScores: Codable {
        let assists: Int
        let creepScore: Int
        let deaths: Int
        let kills: Int
        let wardScore: Double
    }

    struct SummonerSpells: Codable {
        let summonerSpellOne: SpellInfo
        let summonerSpellTwo: SpellInfo

        struct SpellInfo: Codable {
            let displayName: String
            let rawDescription: String?
            let rawDisplayName: String?
        }
    }

    struct PlayerItem: Codable {
        let itemID: Int
        let displayName: String
        let count: Int
        let price: Int?
    }
}

struct LiveEvents: Codable {
    let Events: [LiveEvent]

    struct LiveEvent: Codable {
        let EventID: Int
        let EventName: String
        let EventTime: Double
        let KillerName: String?
        let DragonType: String?
        let InhibKilled: String?
        let Assisters: [String]?
    }
}

struct LiveGameInfo: Codable {
    let gameMode: String
    let gameTime: Double
    let mapName: String
    let mapNumber: Int
    let mapTerrain: String
}
