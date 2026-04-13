import XCTest

/// Tests for LCU champ select data decoding.
final class ChampSelectDataTests: XCTestCase {

    struct ChampSelectSession: Codable {
        let myTeam: [ChampSelectPlayer]?
        let theirTeam: [ChampSelectPlayer]?
        let timer: ChampSelectTimer?
        let localPlayerCellId: Int?
    }

    struct ChampSelectPlayer: Codable {
        let cellId: Int
        let championId: Int
        let assignedPosition: String?
        let summonerInternalName: String?
        let spell1Id: Int?
        let spell2Id: Int?
    }

    struct ChampSelectTimer: Codable {
        let phase: String?
        let timeLeftInPhase: Double?
    }

    struct RunePage: Codable {
        let name: String
        let primaryStyleId: Int
        let subStyleId: Int
        let selectedPerkIds: [Int]
        let current: Bool?
        let id: Int?
    }

    // MARK: - Champ Select Session

    func testDecodeChampSelectSession() throws {
        let json = """
        {
            "myTeam": [
                {
                    "cellId": 0,
                    "championId": 222,
                    "assignedPosition": "BOTTOM",
                    "summonerInternalName": "TestPlayer",
                    "spell1Id": 4,
                    "spell2Id": 7
                }
            ],
            "theirTeam": [
                {
                    "cellId": 5,
                    "championId": 51,
                    "assignedPosition": "BOTTOM"
                }
            ],
            "timer": {
                "phase": "BAN_PICK",
                "timeLeftInPhase": 25.5
            },
            "localPlayerCellId": 0
        }
        """.data(using: .utf8)!

        let session = try JSONDecoder().decode(ChampSelectSession.self, from: json)
        XCTAssertEqual(session.localPlayerCellId, 0)
        XCTAssertEqual(session.myTeam?.count, 1)
        XCTAssertEqual(session.myTeam?[0].championId, 222) // Jinx
        XCTAssertEqual(session.myTeam?[0].assignedPosition, "BOTTOM")
        XCTAssertEqual(session.myTeam?[0].spell1Id, 4) // Flash
        XCTAssertEqual(session.theirTeam?[0].championId, 51) // Caitlyn
        XCTAssertEqual(session.timer?.phase, "BAN_PICK")
    }

    func testDecodeSessionWithNullFields() throws {
        let json = """
        {
            "myTeam": [
                {
                    "cellId": 0,
                    "championId": 0
                }
            ],
            "localPlayerCellId": 0
        }
        """.data(using: .utf8)!

        let session = try JSONDecoder().decode(ChampSelectSession.self, from: json)
        XCTAssertEqual(session.myTeam?[0].championId, 0) // No champion selected yet
        XCTAssertNil(session.myTeam?[0].assignedPosition)
        XCTAssertNil(session.theirTeam)
        XCTAssertNil(session.timer)
    }

    // MARK: - Rune Page

    func testDecodeRunePage() throws {
        let json = """
        {
            "name": "Jinx ADC",
            "primaryStyleId": 8000,
            "subStyleId": 8200,
            "selectedPerkIds": [8021, 8009, 9111, 8299, 8226, 8233],
            "current": true,
            "id": 52
        }
        """.data(using: .utf8)!

        let page = try JSONDecoder().decode(RunePage.self, from: json)
        XCTAssertEqual(page.name, "Jinx ADC")
        XCTAssertEqual(page.primaryStyleId, 8000)
        XCTAssertEqual(page.subStyleId, 8200)
        XCTAssertEqual(page.selectedPerkIds.count, 6)
        XCTAssertEqual(page.current, true)
        XCTAssertEqual(page.id, 52)
    }

    func testEncodeRunePageForImport() throws {
        let page = RunePage(
            name: "Overlay Import",
            primaryStyleId: 8000,
            subStyleId: 8200,
            selectedPerkIds: [8021, 8009, 9111, 8299, 8226, 8233],
            current: nil,
            id: nil
        )

        let data = try JSONEncoder().encode(page)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["name"] as? String, "Overlay Import")
        XCTAssertEqual(json?["primaryStyleId"] as? Int, 8000)
        XCTAssertEqual((json?["selectedPerkIds"] as? [Int])?.count, 6)
    }

    // MARK: - Finding Local Player

    func testFindLocalPlayerInTeam() throws {
        let json = """
        {
            "myTeam": [
                { "cellId": 0, "championId": 86, "assignedPosition": "TOP" },
                { "cellId": 1, "championId": 64, "assignedPosition": "JUNGLE" },
                { "cellId": 2, "championId": 103, "assignedPosition": "MIDDLE" },
                { "cellId": 3, "championId": 222, "assignedPosition": "BOTTOM" },
                { "cellId": 4, "championId": 412, "assignedPosition": "UTILITY" }
            ],
            "localPlayerCellId": 3
        }
        """.data(using: .utf8)!

        let session = try JSONDecoder().decode(ChampSelectSession.self, from: json)
        let me = session.myTeam?.first { $0.cellId == session.localPlayerCellId }
        XCTAssertNotNil(me)
        XCTAssertEqual(me?.championId, 222) // Jinx
        XCTAssertEqual(me?.assignedPosition, "BOTTOM")
    }

    func testLocalPlayerNotFoundIfCellIdMissing() throws {
        let json = """
        {
            "myTeam": [
                { "cellId": 0, "championId": 86 }
            ],
            "localPlayerCellId": 99
        }
        """.data(using: .utf8)!

        let session = try JSONDecoder().decode(ChampSelectSession.self, from: json)
        let me = session.myTeam?.first { $0.cellId == session.localPlayerCellId }
        XCTAssertNil(me)
    }
}
