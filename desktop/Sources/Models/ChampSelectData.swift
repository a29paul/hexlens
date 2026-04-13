import Foundation

/// Models for LCU champ select data

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
