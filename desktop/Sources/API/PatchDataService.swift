import Foundation
import os

/// Fetches and caches per-patch build/rune recommendations.
///
/// Data sources (in priority order):
///   1. CommunityDragon — structured champion data
///   2. Meraki Analytics — champion.json with role-specific builds
///
/// Caches locally per patch version. Falls back to last cached data
/// if fetch fails.
actor PatchDataService {
    static let shared = PatchDataService()

    private let logger = Logger(subsystem: "com.macleagueoverlay", category: "PatchData")
    private let cacheDir: URL
    private var buildData: [String: ChampionBuildData] = [:]
    private var currentPatch: String?

    struct ChampionBuildData {
        let championId: String
        let role: PlayerRole
        let recommendedRunes: RunePage?
        let coreItems: [Int]
        let winRate: Double
        let pickRate: Double
        let gamesAnalyzed: Int
        let matchups: [MatchupData]
        let csBenchmarks: CSBenchmarks?
    }

    struct MatchupData {
        let opponentChampionId: String
        let winRate: Double
        let gamesPlayed: Int
        let tip: String?
    }

    struct CSBenchmarks {
        let role: PlayerRole
        /// CS per minute benchmarks by rank tier at 10-minute intervals
        /// e.g. [10: 80, 20: 170, 30: 250] for Gold ADC
        let csPerMinuteByTime: [Int: Double]
    }

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        cacheDir = appSupport.appendingPathComponent("MacLeagueOverlay/PatchData")
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    /// Load patch data. Call after DataDragon.load().
    func load() async {
        do {
            let patch = try await fetchCurrentPatch()
            currentPatch = patch

            let cacheFile = cacheDir.appendingPathComponent("\(patch)-builds.json")
            if FileManager.default.fileExists(atPath: cacheFile.path) {
                let data = try Data(contentsOf: cacheFile)
                parseBuildData(data)
                logger.info("Loaded build data from cache (patch \(patch))")
            } else {
                let data = try await fetchMerakiData()
                try data.write(to: cacheFile)
                parseBuildData(data)
                logger.info("Fetched and cached build data (patch \(patch))")
            }
        } catch {
            logger.error("Failed to load patch data: \(error.localizedDescription)")
            loadFallbackCache()
        }
    }

    func getBuildData(for championId: String, role: PlayerRole) -> ChampionBuildData? {
        let key = "\(championId)_\(role.rawValue)"
        return buildData[key] ?? buildData[championId]
    }

    nonisolated func getCSBenchmark(role: PlayerRole, gameTimeMinutes: Int) -> Double {
        // Default CS benchmarks by role at gold elo
        switch role {
        case .adc:
            return Double(gameTimeMinutes) * 8.0  // ~8 CS/min target
        case .mid:
            return Double(gameTimeMinutes) * 7.5
        case .top:
            return Double(gameTimeMinutes) * 7.0
        case .jungle:
            return Double(gameTimeMinutes) * 5.5  // jungle CS is lower
        case .support:
            return Double(gameTimeMinutes) * 1.5  // supports barely CS
        case .unknown:
            return Double(gameTimeMinutes) * 7.0
        }
    }

    // MARK: - Fetching

    private func fetchCurrentPatch() async throws -> String {
        let data = try await fetch("https://ddragon.leagueoflegends.com/api/versions.json")
        let versions = try JSONDecoder().decode([String].self, from: data)
        guard let latest = versions.first else {
            throw PatchDataError.noPatch
        }
        // Return major.minor only (e.g. "14.8")
        let parts = latest.split(separator: ".")
        if parts.count >= 2 {
            return "\(parts[0]).\(parts[1])"
        }
        return latest
    }

    private func fetchMerakiData() async throws -> Data {
        // Meraki Analytics provides structured champion data
        let url = "https://cdn.merakianalytics.com/riot/lol/resources/latest/en-US/champions.json"
        return try await fetch(url)
    }

    private nonisolated func fetch(_ urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw PatchDataError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PatchDataError.httpError
        }
        return data
    }

    // MARK: - Parsing

    private func parseBuildData(_ data: Data) {
        // Meraki data is a large JSON object keyed by champion name
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
            logger.warning("Failed to parse build data JSON")
            return
        }

        for (champName, champData) in json {
            // Extract basic stats
            guard let stats = champData["stats"] as? [String: Any] else { continue }

            let winRate = (stats["winRate"] as? Double) ?? 0.5
            let pickRate = (stats["pickRate"] as? Double) ?? 0.0

            let build = ChampionBuildData(
                championId: champName,
                role: .unknown,
                recommendedRunes: nil,
                coreItems: [],
                winRate: winRate,
                pickRate: pickRate,
                gamesAnalyzed: 0,
                matchups: [],
                csBenchmarks: nil
            )

            buildData[champName] = build
        }

        logger.info("Parsed build data for \(self.buildData.count) champions")
    }

    private func loadFallbackCache() {
        // Find the most recent cache file regardless of patch
        let enumerator = FileManager.default.enumerator(at: cacheDir, includingPropertiesForKeys: [.contentModificationDateKey])
        var latestFile: URL?
        var latestDate: Date = .distantPast

        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.pathExtension == "json",
               let attrs = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]),
               let date = attrs.contentModificationDate,
               date > latestDate {
                latestDate = date
                latestFile = fileURL
            }
        }

        if let file = latestFile, let data = try? Data(contentsOf: file) {
            parseBuildData(data)
            logger.info("Loaded fallback cache from \(file.lastPathComponent)")
        }
    }
}

enum PatchDataError: Error {
    case invalidURL
    case httpError
    case noPatch
}
