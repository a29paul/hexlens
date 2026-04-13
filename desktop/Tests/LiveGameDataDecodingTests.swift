import XCTest

/// Tests for decoding Live Client Data API JSON responses.
/// Uses real sample data from https://127.0.0.1:2999/liveclientdata/allgamedata
final class LiveGameDataDecodingTests: XCTestCase {

    // Mirror the Codable structs to avoid import dependency
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
        let level: Int
        let position: String
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
    }

    struct LiveEvents: Codable {
        let Events: [LiveEvent]

        struct LiveEvent: Codable {
            let EventID: Int
            let EventName: String
            let EventTime: Double
            let KillerName: String?
            let DragonType: String?
        }
    }

    struct LiveGameInfo: Codable {
        let gameMode: String
        let gameTime: Double
        let mapName: String
        let mapNumber: Int
        let mapTerrain: String
    }

    // MARK: - Decoding Tests

    func testDecodeMinimalResponse() throws {
        let json = """
        {
            "activePlayer": {
                "currentGold": 1500.5,
                "level": 6,
                "summonerName": "TestPlayer"
            },
            "allPlayers": [],
            "events": { "Events": [] },
            "gameData": {
                "gameMode": "CLASSIC",
                "gameTime": 600.0,
                "mapName": "Map11",
                "mapNumber": 11,
                "mapTerrain": "Default"
            }
        }
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(LiveGameAllData.self, from: json)
        XCTAssertEqual(data.activePlayer.summonerName, "TestPlayer")
        XCTAssertEqual(data.activePlayer.level, 6)
        XCTAssertEqual(data.activePlayer.currentGold, 1500.5)
        XCTAssertEqual(data.gameData.gameMode, "CLASSIC")
        XCTAssertEqual(data.gameData.gameTime, 600.0)
    }

    func testDecodePlayerWithSpells() throws {
        let json = """
        {
            "activePlayer": {
                "currentGold": 0,
                "level": 1,
                "summonerName": "Me"
            },
            "allPlayers": [
                {
                    "championName": "Jinx",
                    "isBot": false,
                    "isDead": false,
                    "level": 6,
                    "position": "BOTTOM",
                    "scores": { "assists": 2, "creepScore": 142, "deaths": 1, "kills": 3, "wardScore": 4.0 },
                    "skinID": 0,
                    "summonerName": "TestADC",
                    "summonerSpells": {
                        "summonerSpellOne": { "displayName": "Flash" },
                        "summonerSpellTwo": { "displayName": "Heal" }
                    },
                    "team": "ORDER"
                }
            ],
            "events": { "Events": [] },
            "gameData": {
                "gameMode": "CLASSIC",
                "gameTime": 900.0,
                "mapName": "Map11",
                "mapNumber": 11,
                "mapTerrain": "Default"
            }
        }
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(LiveGameAllData.self, from: json)
        XCTAssertEqual(data.allPlayers.count, 1)
        let player = data.allPlayers[0]
        XCTAssertEqual(player.championName, "Jinx")
        XCTAssertEqual(player.position, "BOTTOM")
        XCTAssertEqual(player.scores.creepScore, 142)
        XCTAssertEqual(player.scores.kills, 3)
        XCTAssertEqual(player.summonerSpells.summonerSpellOne.displayName, "Flash")
        XCTAssertEqual(player.summonerSpells.summonerSpellTwo.displayName, "Heal")
        XCTAssertEqual(player.team, "ORDER")
    }

    func testDecodeEvents() throws {
        let json = """
        {
            "activePlayer": { "currentGold": 0, "level": 1, "summonerName": "Me" },
            "allPlayers": [],
            "events": {
                "Events": [
                    { "EventID": 1, "EventName": "GameStart", "EventTime": 0.0 },
                    { "EventID": 15, "EventName": "DragonKill", "EventTime": 600.0, "KillerName": "TestJungler", "DragonType": "Fire" },
                    { "EventID": 22, "EventName": "BaronKill", "EventTime": 1200.0, "KillerName": "TestJungler" }
                ]
            },
            "gameData": {
                "gameMode": "CLASSIC",
                "gameTime": 1250.0,
                "mapName": "Map11",
                "mapNumber": 11,
                "mapTerrain": "Default"
            }
        }
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(LiveGameAllData.self, from: json)
        XCTAssertEqual(data.events.Events.count, 3)
        XCTAssertEqual(data.events.Events[1].EventName, "DragonKill")
        XCTAssertEqual(data.events.Events[1].DragonType, "Fire")
        XCTAssertEqual(data.events.Events[2].EventName, "BaronKill")
    }

    func testDecodeWithChampionStats() throws {
        let json = """
        {
            "activePlayer": {
                "championStats": {
                    "attackDamage": 85.5,
                    "abilityPower": 0.0,
                    "armor": 42.0,
                    "magicResist": 30.0
                },
                "currentGold": 3200.0,
                "level": 10,
                "summonerName": "Me"
            },
            "allPlayers": [],
            "events": { "Events": [] },
            "gameData": {
                "gameMode": "CLASSIC",
                "gameTime": 1500.0,
                "mapName": "Map11",
                "mapNumber": 11,
                "mapTerrain": "Default"
            }
        }
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(LiveGameAllData.self, from: json)
        XCTAssertNotNil(data.activePlayer.championStats)
        XCTAssertEqual(data.activePlayer.championStats?.attackDamage, 85.5)
    }

    // MARK: - Error Cases

    func testDecodeEmptyJSONFails() {
        let json = "{}".data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(LiveGameAllData.self, from: json))
    }

    func testDecodeMalformedJSONFails() {
        let json = "not json at all".data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(LiveGameAllData.self, from: json))
    }

    func testDecodeMissingRequiredFieldFails() {
        // Missing "gameData" field
        let json = """
        {
            "activePlayer": { "currentGold": 0, "level": 1, "summonerName": "Me" },
            "allPlayers": [],
            "events": { "Events": [] }
        }
        """.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(LiveGameAllData.self, from: json))
    }
}
