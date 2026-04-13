import Foundation
import os

/// Fetches static game data from Riot's Data Dragon CDN.
/// Champion names, icons, item images, rune data, summoner spell info.
///
/// Thread-safe via actor isolation. All mutable state is protected.
///
/// Data Dragon URL pattern:
///   https://ddragon.leagueoflegends.com/cdn/{version}/data/en_US/{file}.json
///
/// Cached locally per patch version.
actor DataDragon {
    static let shared = DataDragon()

    private let logger = Logger(subsystem: "com.macleagueoverlay", category: "DataDragon")
    private let cacheDir: URL
    private var champions: [Int: ChampionInfo] = [:]
    private var summonerSpells: [Int: SummonerSpellInfo] = [:]
    /// Ult cooldowns per champion name → [rank1, rank2, rank3]
    private var ultCooldowns: [String: [Double]] = [:]
    private var currentVersion: String?
    private var isLoaded = false

    struct ChampionInfo: Sendable {
        let id: String
        let name: String
        let key: Int
        let title: String
    }

    struct SummonerSpellInfo: Sendable {
        let id: String
        let name: String
        let key: Int
        let cooldown: TimeInterval
    }

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        cacheDir = appSupport.appendingPathComponent("MacLeagueOverlay/DataDragon")
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    /// Load Data Dragon for the current patch. Call once on app start.
    func load() async {
        do {
            let version = try await fetchLatestVersion()
            currentVersion = version

            let cacheFile = cacheDir.appendingPathComponent("\(version)-champions.json")
            if FileManager.default.fileExists(atPath: cacheFile.path) {
                let data = try Data(contentsOf: cacheFile)
                parseChampionData(data)
                logger.info("Loaded champions from cache (patch \(version))")
            } else {
                let data = try await fetchJSON("https://ddragon.leagueoflegends.com/cdn/\(version)/data/en_US/champion.json")
                try data.write(to: cacheFile)
                parseChampionData(data)
                logger.info("Fetched and cached champions (patch \(version))")
            }

            let spellCache = cacheDir.appendingPathComponent("\(version)-summoner.json")
            if FileManager.default.fileExists(atPath: spellCache.path) {
                let data = try Data(contentsOf: spellCache)
                parseSummonerSpellData(data)
            } else {
                let data = try await fetchJSON("https://ddragon.leagueoflegends.com/cdn/\(version)/data/en_US/summoner.json")
                try data.write(to: spellCache)
                parseSummonerSpellData(data)
            }

            // Ult cooldowns from Meraki (per-champion)
            let ultCache = cacheDir.appendingPathComponent("\(version)-ultcooldowns.json")
            if FileManager.default.fileExists(atPath: ultCache.path) {
                let data = try Data(contentsOf: ultCache)
                parseUltCooldowns(data)
                logger.info("Loaded ult cooldowns from cache (patch \(version))")
            } else {
                await fetchAllUltCooldowns()
                // Cache the result
                if let jsonData = try? JSONSerialization.data(withJSONObject: ultCooldowns.mapValues { $0 }) {
                    try? jsonData.write(to: ultCache)
                }
                logger.info("Fetched ult cooldowns for \(self.ultCooldowns.count) champions")
            }

            isLoaded = true
        } catch {
            logger.error("Failed to load Data Dragon: \(error.localizedDescription)")
        }
    }

    func championName(for id: Int) -> String {
        champions[id]?.name ?? "Champion \(id)"
    }

    /// Get ult cooldown for a champion at a specific rank (1-3).
    /// Returns the base cooldown in seconds from Meraki data.
    func ultCooldown(champion: String, rank: Int) -> TimeInterval {
        guard let cds = ultCooldowns[champion], rank >= 1, rank <= cds.count else {
            // Fallback for champions not yet loaded
            return [120, 100, 80][min(max(rank - 1, 0), 2)]
        }
        return cds[rank - 1]
    }

    /// Get all cached ult cooldowns for synchronous access by GameStateManager.
    func allUltCooldowns() -> [String: [Double]] {
        ultCooldowns
    }

    func summonerSpellName(for id: Int) -> String {
        summonerSpells[id]?.name ?? "Spell \(id)"
    }

    func summonerSpellCooldown(for id: Int) -> TimeInterval {
        summonerSpells[id]?.cooldown ?? 300
    }

    // MARK: - Fetching

    private func fetchLatestVersion() async throws -> String {
        let data = try await fetchJSON("https://ddragon.leagueoflegends.com/api/versions.json")
        let versions = try JSONDecoder().decode([String].self, from: data)
        guard let latest = versions.first else {
            throw DataDragonError.noVersions
        }
        return latest
    }

    private nonisolated func fetchJSON(_ urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw DataDragonError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DataDragonError.httpError
        }
        return data
    }

    // MARK: - Parsing

    private func parseChampionData(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataDict = json["data"] as? [String: [String: Any]] else { return }

        for (_, champData) in dataDict {
            guard let keyStr = champData["key"] as? String,
                  let key = Int(keyStr),
                  let id = champData["id"] as? String,
                  let name = champData["name"] as? String,
                  let title = champData["title"] as? String else { continue }

            champions[key] = ChampionInfo(id: id, name: name, key: key, title: title)
        }

        logger.info("Parsed \(self.champions.count) champions")
    }

    private func parseSummonerSpellData(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataDict = json["data"] as? [String: [String: Any]] else { return }

        for (_, spellData) in dataDict {
            guard let keyStr = spellData["key"] as? String,
                  let key = Int(keyStr),
                  let id = spellData["id"] as? String,
                  let name = spellData["name"] as? String else { continue }

            let cooldownArr = spellData["cooldown"] as? [Double]
            let cooldown = cooldownArr?.first ?? 300

            summonerSpells[key] = SummonerSpellInfo(id: id, name: name, key: key, cooldown: cooldown)
        }

        logger.info("Parsed \(self.summonerSpells.count) summoner spells")
    }

    /// Fetch ult cooldowns for all champions from Meraki Analytics.
    /// Each champion has a separate JSON endpoint.
    private func fetchAllUltCooldowns() async {
        let champNames = champions.values.map { $0.id }
        for champId in champNames {
            do {
                let data = try await fetchJSON("https://cdn.merakianalytics.com/riot/lol/resources/latest/en-US/champions/\(champId).json")
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let abilities = json["abilities"] as? [String: Any],
                      let rAbilities = abilities["R"] as? [[String: Any]],
                      let firstR = rAbilities.first,
                      let cooldown = firstR["cooldown"] as? [String: Any],
                      let modifiers = cooldown["modifiers"] as? [[String: Any]],
                      let firstMod = modifiers.first,
                      let values = firstMod["values"] as? [Double] else { continue }

                // Meraki uses champion name (display name), not id
                let displayName = (json["name"] as? String) ?? champId
                ultCooldowns[displayName] = values
            } catch {
                // Skip individual champion failures silently
                continue
            }
        }
        logger.info("Fetched ult cooldowns for \(self.ultCooldowns.count) champions")
    }

    private func parseUltCooldowns(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: [Double]] else { return }
        ultCooldowns = json
    }
}

enum DataDragonError: Error {
    case invalidURL
    case httpError
    case noVersions
}
