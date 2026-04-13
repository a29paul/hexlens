import Foundation
import Combine
import os

/// Central state manager for the entire app. Coordinates between
/// GameDetector, LCUClient, and LiveGameClient. Drives all UI state.
///
/// State machine:
///   IDLE → LOBBY → CHAMP_SELECT → LOADING → IN_GAME → POST_GAME → IDLE
class GameStateManager: ObservableObject {
    @Published var state: GameLifecycleState = .idle
    private var stateVersion: Int = 0  // increments on each transition, cancels deferred actions
    @Published var currentCS: Int = 0
    @Published var csBenchmarkDiff: Int = 0
    @Published var playerRole: PlayerRole = .unknown
    @Published var jungleTimers: [JungleTimer] = GameStateManager.defaultTimers()
    @Published var enemySpells: [EnemySpellState] = []
    @Published var allies: [AllyState] = []
    @Published var inhibitorTimers: [InhibitorTimer] = []
    @Published var goldLead: Int = 0  // positive = our team ahead
    @Published var csPerMin: Double = 0
    @Published var goldPerMin: Double = 0
    @Published var killParticipation: Double = 0  // 0-100%
    @Published var visionPerMin: Double = 0
    @Published var playerLevel: Int = 0
    @Published var kda: (kills: Int, deaths: Int, assists: Int) = (0, 0, 0)
    @Published var allyTeamGold: Int = 0
    @Published var enemyTeamGold: Int = 0
    @Published var laneMatchups: [LaneMatchup] = []
    @Published var champSelectSession: ChampSelectSession?
    @Published var activePlayerName: String = ""
    private var lastProcessedEnemies: [LivePlayer] = []
    /// Dragon buffs per team: ["ORDER": ["Cloud", "Cloud", "Fire"], "CHAOS": ["Water"]]
    private var dragonsByTeam: [String: [String]] = [:]
    private var processedDragonEventIDs: Set<Int> = []
    /// Cached ult cooldowns from DataDragon actor, keyed by champion name → [rank1CD, rank2CD, rank3CD]
    private var cachedUltCooldowns: [String: [Double]] = [:]
    @Published var dataDragonVersion: String = "15.7.1"  // fallback, updated on load

    private let logger = Logger(subsystem: "com.macleagueoverlay", category: "GameState")
    private var gameDetector: GameDetector?
    private var lcuClient: LCUClient?
    private var liveGameClient: LiveGameClient?
    private var timerEngine: TimerEngine?
    private var pollTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    func start() {
        gameDetector = GameDetector()
        timerEngine = TimerEngine()

        gameDetector?.onProcessFound = { [weak self] lockfileData in
            self?.handleProcessFound(lockfileData)
        }
        gameDetector?.onProcessLost = { [weak self] in
            DispatchQueue.main.async {
                self?.transitionTo(.idle)
            }
        }

        gameDetector?.startWatching()

        // Load data sources
        Task {
            await DataDragon.shared.load()
            await PatchDataService.shared.load()
            // Cache ult cooldowns for synchronous access during gameplay
            await self.refreshUltCooldownCache()
        }

        logger.info("GameStateManager started, watching for LoL process")
    }

    // MARK: - State Transitions

    func transitionTo(_ newState: GameLifecycleState) {
        let oldState = state
        guard isValidTransition(from: oldState, to: newState) else {
            logger.warning("Invalid transition: \(oldState.rawValue) → \(newState.rawValue)")
            return
        }

        logger.info("State: \(oldState.rawValue) → \(newState.rawValue)")
        state = newState
        stateVersion += 1
        let capturedVersion = stateVersion

        switch newState {
        case .idle:
            cleanup()
        case .lobby:
            break
        case .champSelect:
            break
        case .loading:
            startLiveGamePolling()
        case .inGame:
            break  // spell tracking is now click-based in the overlay UI
        case .postGame:
            stopLiveGamePolling()
            // Return to idle after 3 seconds (cancelled if state changes before then)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard self?.stateVersion == capturedVersion else { return }
                self?.transitionTo(.idle)
            }
        }
    }

    private func isValidTransition(from: GameLifecycleState, to: GameLifecycleState) -> Bool {
        switch (from, to) {
        case (.idle, .lobby), (.idle, .idle): return true
        case (.lobby, .champSelect), (.lobby, .loading), (.lobby, .idle): return true
        case (.champSelect, .loading), (.champSelect, .lobby), (.champSelect, .idle): return true
        case (.loading, .inGame), (.loading, .idle), (.loading, .lobby): return true
        case (.inGame, .postGame), (.inGame, .idle): return true
        case (.postGame, .idle), (.postGame, .lobby): return true
        default: return false
        }
    }

    // MARK: - Process Detection

    private func handleProcessFound(_ lockfileData: LockfileData) {
        logger.info("LoL process found, connecting to LCU on port \(lockfileData.port)")
        DispatchQueue.main.async { [weak self] in
            self?.transitionTo(.lobby)
            // Check if a game is already in progress (app launched mid-game)
            self?.checkForActiveGame()
        }

        lcuClient = LCUClient(lockfileData: lockfileData)
        lcuClient?.onChampSelect = { [weak self] session in
            DispatchQueue.main.async {
                self?.champSelectSession = session
                if self?.state == .lobby {
                    self?.transitionTo(.champSelect)
                }
            }
        }
        lcuClient?.onChampSelectEnd = { [weak self] in
            DispatchQueue.main.async {
                guard self?.state == .champSelect else { return }
                // Champ select ended — could be game start OR dodge.
                // Transition to loading; if the live game API doesn't respond
                // within 30 seconds, it was a dodge — fall back to lobby.
                self?.transitionTo(.loading)
                let version = self?.stateVersion ?? 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
                    guard self?.stateVersion == version, self?.state == .loading else { return }
                    self?.logger.info("Loading timeout — likely a dodge, returning to lobby")
                    self?.transitionTo(.lobby)
                }
            }
        }
        lcuClient?.onDodge = { [weak self] in
            DispatchQueue.main.async {
                if self?.state == .champSelect || self?.state == .loading {
                    self?.transitionTo(.lobby)
                }
            }
        }
        lcuClient?.onConnectionFailed = { [weak self] in
            DispatchQueue.main.async {
                self?.logger.warning("LCU connection permanently failed, resetting detection")
                self?.lcuClient = nil
                self?.gameDetector?.resetWasRunning()
            }
        }
        lcuClient?.connect()
    }

    /// Check if a game is already in progress (handles app launched mid-game).
    /// Probes the Live Client Data API directly. If it responds, skip straight
    /// to LOADING → IN_GAME without waiting for LCU champ select events.
    private func checkForActiveGame() {
        let client = LiveGameClient()
        client.fetchAllGameData { [weak self] result in
            DispatchQueue.main.async {
                if case .success = result {
                    self?.logger.info("Active game detected on startup, jumping to loading")
                    if self?.state == .lobby || self?.state == .idle {
                        self?.transitionTo(.loading)
                    }
                }
            }
        }
    }

    // MARK: - Live Game Polling

    private func startLiveGamePolling() {
        liveGameClient = LiveGameClient()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.pollLiveGame()
        }
    }

    private func stopLiveGamePolling() {
        pollTimer?.invalidate()
        pollTimer = nil
        liveGameClient = nil
    }

    private var consecutiveFailures = 0
    private var backoffInterval: TimeInterval = 1.0

    private func debugLog(_ msg: String) {
        let line = "[\(Date())] [GSM] \(msg)\n"
        if let data = line.data(using: .utf8) {
            let logFile = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("hexlens-debug.log")
            let handle = try? FileHandle(forWritingTo: logFile)
            handle?.seekToEndOfFile()
            handle?.write(data)
            handle?.closeFile()
        }
    }

    private func pollLiveGame() {
        liveGameClient?.fetchAllGameData { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    let timersStr = self?.jungleTimers.map { "\($0.id)=\($0.displayValue)" }.joined(separator: ", ") ?? "none"
                    self?.debugLog("poll: time=\(Int(data.gameData.gameTime))s cs=\(self?.currentCS ?? 0) gold=\(self?.goldLead ?? 0) timers=[\(timersStr)] enemies=\(self?.enemySpells.count ?? 0)")
                    let wasInBackoff = (self?.consecutiveFailures ?? 0) >= 3
                    self?.consecutiveFailures = 0
                    self?.backoffInterval = 1.0
                    self?.processLiveGameData(data)
                    if self?.state == .loading {
                        self?.transitionTo(.inGame)
                    }
                    // Restore 1s polling if we were in backoff
                    if wasInBackoff {
                        self?.pollTimer?.invalidate()
                        self?.pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                            self?.pollLiveGame()
                        }
                    }
                case .failure(let error):
                    self?.debugLog("poll FAILED: \(error)")
                    self?.handlePollFailure(error)
                }
            }
        }
    }

    private func handlePollFailure(_ error: Error) {
        consecutiveFailures += 1
        logger.warning("Live game poll failed (\(self.consecutiveFailures)x): \(error.localizedDescription)")
        if consecutiveFailures >= 3 {
            backoffInterval = min(backoffInterval * 2, 10.0)
            // Invalidate existing timer before creating a new one to prevent stacking
            pollTimer?.invalidate()
            pollTimer = nil
            pollTimer = Timer.scheduledTimer(withTimeInterval: backoffInterval, repeats: true) { [weak self] _ in
                self?.pollLiveGame()
            }
        }
    }

    // MARK: - Data Processing

    private func processLiveGameData(_ data: LiveGameAllData) {
        // Find active player
        activePlayerName = data.activePlayer.summonerName
        let me = data.allPlayers.first { $0.summonerName == activePlayerName }

        // Role detection (before benchmark so benchmark uses current role)
        if let position = me?.position {
            playerRole = PlayerRole(rawValue: position.lowercased()) ?? .unknown
        }

        // CS + benchmark
        currentCS = me?.scores.creepScore ?? 0
        let gameMinutes = Int(data.gameData.gameTime / 60)
        let gameMinutesF = max(data.gameData.gameTime / 60.0, 0.1)
        let benchmark = PatchDataService.shared.getCSBenchmark(role: playerRole, gameTimeMinutes: max(gameMinutes, 1))
        csBenchmarkDiff = currentCS - Int(benchmark)

        // Per-minute stats
        playerLevel = me?.level ?? 0
        csPerMin = Double(currentCS) / gameMinutesF
        visionPerMin = (me?.scores.wardScore ?? 0) / gameMinutesF
        kda = (kills: me?.scores.kills ?? 0, deaths: me?.scores.deaths ?? 0, assists: me?.scores.assists ?? 0)

        // Gold per min from items
        let myItemGold = (me?.items ?? []).reduce(0) { $0 + ($1.price ?? 0) * $1.count }
        goldPerMin = Double(myItemGold) / gameMinutesF

        // Kill participation: (my kills + assists) / team total kills
        let myTeamPlayers = data.allPlayers.filter { $0.team == (me?.team ?? "") }
        let teamKills = myTeamPlayers.reduce(0) { $0 + $1.scores.kills }
        if teamKills > 0 {
            killParticipation = Double((me?.scores.kills ?? 0) + (me?.scores.assists ?? 0)) / Double(teamKills) * 100.0
        } else {
            killParticipation = 0
        }

        // Process events for timers
        timerEngine?.processEvents(data.events.Events, gameTime: data.gameData.gameTime)
        jungleTimers = timerEngine?.timers ?? GameStateManager.defaultTimers()

        // Build enemy spell states — only if we know our team
        guard let myTeam = me?.team, !myTeam.isEmpty else { return }
        let enemies = data.allPlayers.filter { $0.team != myTeam }.sorted { $0.summonerName < $1.summonerName }
        lastProcessedEnemies = enemies
        enemySpells = enemies.prefix(5).map { enemy in
            let existing = self.enemySpells.first { $0.championName == enemy.championName }
            return EnemySpellState(
                id: enemy.championName,
                championName: enemy.championName,
                spell1: existing?.spell1 ?? SpellCooldownState(
                    spellName: enemy.summonerSpells.summonerSpellOne.displayName,
                    rawDisplayName: enemy.summonerSpells.summonerSpellOne.rawDisplayName,
                    baseCooldown: spellBaseCooldown(enemy.summonerSpells.summonerSpellOne.displayName)
                ),
                spell2: existing?.spell2 ?? SpellCooldownState(
                    spellName: enemy.summonerSpells.summonerSpellTwo.displayName,
                    rawDisplayName: enemy.summonerSpells.summonerSpellTwo.rawDisplayName,
                    baseCooldown: spellBaseCooldown(enemy.summonerSpells.summonerSpellTwo.displayName)
                ),
                ult: existing?.ult ?? SpellCooldownState(
                    spellName: "R",
                    baseCooldown: ultBaseCooldown(championName: enemy.championName, level: enemy.level)
                ),
                level: enemy.level
            )
        }

        // Ally tracking (teammates excluding self)
        let allyPlayers = data.allPlayers.filter { $0.team == myTeam && $0.summonerName != activePlayerName }
        allies = allyPlayers.map { ally in
            AllyState(
                id: ally.summonerName,
                championName: ally.championName,
                summonerName: ally.summonerName,
                level: ally.level,
                isDead: ally.isDead,
                respawnTimer: ally.respawnTimer,
                ultReady: ally.level >= 6 && !ally.isDead,
                spell1Name: ally.summonerSpells.summonerSpellOne.displayName,
                spell2Name: ally.summonerSpells.summonerSpellTwo.displayName
            )
        }

        // Gold tracking from actual item prices
        func playerItemGold(_ player: LivePlayer) -> Int {
            (player.items ?? []).reduce(0) { $0 + ($1.price ?? 0) * $1.count }
        }

        let allyPlayers2 = data.allPlayers.filter { $0.team == myTeam }
        let enemyPlayers = data.allPlayers.filter { $0.team != myTeam }

        allyTeamGold = allyPlayers2.reduce(0) { $0 + playerItemGold($1) }
        enemyTeamGold = enemyPlayers.reduce(0) { $0 + playerItemGold($1) }
        goldLead = allyTeamGold - enemyTeamGold

        // Lane matchups: match by position first, then pair leftovers
        let allyByPos = Dictionary(grouping: allyPlayers2, by: { $0.position }).compactMapValues(\.first)
        let enemyByPos = Dictionary(grouping: enemyPlayers, by: { $0.position }).compactMapValues(\.first)
        var matchups: [LaneMatchup] = []
        var matchedAllyNames = Set<String>()
        var matchedEnemyNames = Set<String>()

        for pos in ["TOP", "JUNGLE", "MIDDLE", "BOTTOM", "UTILITY"] {
            if let ally = allyByPos[pos], let enemy = enemyByPos[pos] {
                matchups.append(LaneMatchup(
                    id: pos,
                    position: pos,
                    allyChampion: ally.championName,
                    enemyChampion: enemy.championName,
                    allyGold: playerItemGold(ally),
                    enemyGold: playerItemGold(enemy)
                ))
                matchedAllyNames.insert(ally.championName)
                matchedEnemyNames.insert(enemy.championName)
            }
        }

        // Pair unmatched players (e.g. bot + support mismatch)
        let unmatchedAllies = allyPlayers2.filter { !matchedAllyNames.contains($0.championName) }
        let unmatchedEnemies = enemyPlayers.filter { !matchedEnemyNames.contains($0.championName) }
        for (ally, enemy) in zip(unmatchedAllies, unmatchedEnemies) {
            let pos = ally.position.isEmpty ? enemy.position : ally.position
            matchups.append(LaneMatchup(
                id: "\(ally.championName)-\(enemy.championName)",
                position: pos,
                allyChampion: ally.championName,
                enemyChampion: enemy.championName,
                allyGold: playerItemGold(ally),
                enemyGold: playerItemGold(enemy)
            ))
        }

        laneMatchups = matchups

        // Inhibitor timers from events
        processDragonEvents(data.events.Events, allPlayers: data.allPlayers)
        processInhibitorEvents(data.events.Events, gameTime: data.gameData.gameTime)
    }

    private func processDragonEvents(_ events: [LiveEvents.LiveEvent], allPlayers: [LivePlayer]) {
        for event in events {
            guard event.EventName == "DragonKill",
                  !processedDragonEventIDs.contains(event.EventID),
                  let killerName = event.KillerName,
                  let dragonType = event.DragonType else { continue }

            processedDragonEventIDs.insert(event.EventID)

            // Find which team the killer is on
            // KillerName can be "ChampName Bot" for bots or summoner name for players
            var killerTeam: String?
            for player in allPlayers {
                if player.summonerName == killerName
                    || player.championName == killerName
                    || killerName.hasPrefix(player.championName) {
                    killerTeam = player.team
                    break
                }
            }

            if let team = killerTeam {
                dragonsByTeam[team, default: []].append(dragonType)
                logger.info("Dragon \(dragonType) taken by \(team) (total: \(self.dragonsByTeam[team]?.count ?? 0))")
            }
        }
    }

    private func processInhibitorEvents(_ events: [LiveEvents.LiveEvent], gameTime: Double) {
        for event in events {
            guard event.EventName == "InhibKilled" else { continue }
            // Inhibitors respawn after 5 minutes (300s)
            let timeSinceEvent = gameTime - event.EventTime
            let remaining = 300 - timeSinceEvent
            if remaining > 0 {
                let inhibId = event.InhibKilled ?? "unknown"
                let lane = inhibId.contains("Top") ? "top" : inhibId.contains("Bot") ? "bot" : "mid"
                let team = inhibId.contains("T1") ? "ORDER" : "CHAOS"

                if let idx = inhibitorTimers.firstIndex(where: { $0.id == inhibId }) {
                    inhibitorTimers[idx].respawnTime = Date().addingTimeInterval(remaining)
                } else {
                    inhibitorTimers.append(InhibitorTimer(
                        id: inhibId,
                        lane: lane,
                        team: team,
                        respawnTime: Date().addingTimeInterval(remaining)
                    ))
                }
            }
        }
        // Remove expired timers
        inhibitorTimers.removeAll { $0.isAlive }
    }

    // MARK: - Spell Tracking

    func markSpellUsed(enemyIndex: Int, spellIndex: Int) {
        guard enemyIndex < enemySpells.count else { return }
        var enemy = enemySpells[enemyIndex]
        if spellIndex == 0 {
            enemy.spell1.cooldownEnd = Date().addingTimeInterval(enemy.spell1.baseCooldown)
        } else {
            enemy.spell2.cooldownEnd = Date().addingTimeInterval(enemy.spell2.baseCooldown)
        }
        enemySpells[enemyIndex] = enemy
        logger.info("Marked \(enemy.championName) spell \(spellIndex + 1) on cooldown (\(spellIndex == 0 ? enemy.spell1.baseCooldown : enemy.spell2.baseCooldown)s)")
    }

    func markUltUsed(enemyIndex: Int) {
        guard enemyIndex < enemySpells.count else { return }
        var enemy = enemySpells[enemyIndex]
        let cd = ultBaseCooldown(championName: enemy.championName, level: enemy.level)
        enemy.ult.baseCooldown = cd
        enemy.ult.cooldownEnd = Date().addingTimeInterval(cd)
        enemySpells[enemyIndex] = enemy
        logger.info("Marked \(enemy.championName) ult on cooldown (\(cd)s)")
    }

    // MARK: - Rune Import

    func importRunes(_ page: RunePage) {
        guard let lcuClient = lcuClient else {
            logger.warning("Cannot import runes: LCU not connected")
            return
        }
        lcuClient.importRunes(page) { [weak self] result in
            switch result {
            case .success:
                self?.logger.info("Runes imported successfully")
            case .failure(let error):
                self?.logger.error("Rune import failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Cleanup

    private func cleanup() {
        stopLiveGamePolling()
        lcuClient?.disconnect()
        lcuClient = nil
        currentCS = 0
        csBenchmarkDiff = 0
        playerRole = .unknown
        csPerMin = 0
        goldPerMin = 0
        killParticipation = 0
        visionPerMin = 0
        playerLevel = 0
        kda = (0, 0, 0)
        enemySpells = []
        allies = []
        inhibitorTimers = []
        goldLead = 0
        allyTeamGold = 0
        enemyTeamGold = 0
        laneMatchups = []
        lastProcessedEnemies = []
        dragonsByTeam = [:]
        processedDragonEventIDs = []
        jungleTimers = GameStateManager.defaultTimers()
        champSelectSession = nil
        consecutiveFailures = 0
        backoffInterval = 1.0
    }

    // MARK: - Helpers

    static func defaultTimers() -> [JungleTimer] {
        [
            JungleTimer(id: "dragon", name: "Dragon", icon: "🐉", isAlive: true),
            JungleTimer(id: "baron", name: "Baron", icon: "👹", isAlive: true),
            JungleTimer(id: "blue_enemy", name: "Blue (Enemy)", icon: "🔵", isAlive: true),
            JungleTimer(id: "red_enemy", name: "Red (Enemy)", icon: "🔴", isAlive: true),
        ]
    }

    private func refreshUltCooldownCache() async {
        let allCDs = await DataDragon.shared.allUltCooldowns()
        let version = await DataDragon.shared.patchVersion()
        await MainActor.run {
            cachedUltCooldowns = allCDs
            if let v = version { dataDragonVersion = v }
            logger.info("Cached ult cooldowns for \(allCDs.count) champions, version \(self.dataDragonVersion)")
        }
    }

    private func spellBaseCooldown(_ name: String) -> TimeInterval {
        switch name.lowercased() {
        case "flash": return 300
        case "teleport": return 360
        case "ignite": return 180
        case "exhaust": return 210
        case "heal": return 240
        case "barrier": return 180
        case "cleanse": return 210
        case "ghost": return 210
        case "smite": return 90
        default: return 300
        }
    }

    /// Ult cooldown based on champion-specific base CD at ult rank, reduced by
    /// estimated ability haste from the enemy's items.
    ///
    /// Formula: effective_cd = base_cd * (100 / (100 + ability_haste))
    /// Ult cooldown = Meraki base CD × ability haste reduction from items.
    /// Base CD comes from Meraki (170+ champions, updated per patch).
    /// Ability haste estimated from enemy's visible items.
    private func ultBaseCooldown(championName: String, level: Int) -> TimeInterval {
        let rank = level >= 16 ? 3 : level >= 11 ? 2 : 1

        // Get base CD from Meraki via DataDragon (synchronous read from cached data)
        // DataDragon is an actor, so we can't await here. Use the cached value
        // that was set during processLiveGameData's previous cycle.
        let baseCD = cachedUltCooldowns[championName]?[safe: rank - 1] ?? [120, 100, 80][rank - 1]

        // Estimate ability haste from enemy items
        let enemyPlayer = lastProcessedEnemies.first { $0.championName == championName }
        let abilityHaste = estimateAbilityHaste(items: enemyPlayer?.items ?? [])

        // effective_cd = base_cd * (100 / (100 + AH))
        let effectiveCD = baseCD * (100.0 / (100.0 + Double(abilityHaste)))
        return effectiveCD
    }

    /// Estimate ability haste from a player's item list.
    /// Uses known item → AH mappings for common items.
    private func estimateAbilityHaste(items: [LivePlayer.PlayerItem]) -> Int {
        var totalAH = 0
        for item in items {
            totalAH += itemAbilityHaste(itemName: item.displayName)
        }
        return totalAH
    }

    /// Known ability haste values for common items (Season 15 approximate).
    /// Safe array subscript that returns nil instead of crashing on out-of-bounds.
    private func itemAbilityHaste(itemName: String) -> Int {
        let ahByItem: [String: Int] = [
            // Mage items
            "Luden's Echo": 25,
            "Liandry's Torment": 25,
            "Blackfire Torch": 25,
            "Cosmic Drive": 30,
            "Malignance": 25,
            "Horizon Focus": 15,
            "Banshee's Veil": 15,
            "Zhonya's Hourglass": 15,

            // AD items
            "Black Cleaver": 25,
            "Trinity Force": 25,
            "Essence Reaver": 20,
            "Navori Flickerblade": 20,
            "Spear of Shojin": 20,
            "Maw of Malmortius": 15,
            "Death's Dance": 15,
            "Serylda's Grudge": 15,

            // Support items
            "Redemption": 20,
            "Locket of the Iron Solari": 20,
            "Shurelya's Battlesong": 25,
            "Moonstone Renewer": 25,
            "Staff of Flowing Water": 15,
            "Mikael's Blessing": 15,
            "Imperial Mandate": 25,

            // Tank items
            "Frozen Heart": 20,
            "Spirit Visage": 15,
            "Force of Nature": 10,
            "Warmog's Armor": 10,
            "Iceborn Gauntlet": 25,
            "Jak'Sho, The Protean": 15,
            "Sunfire Aegis": 15,
            "Hollow Radiance": 15,
            "Unending Despair": 15,

            // Boots
            "Ionian Boots of Lucidity": 20,

            // Components
            "Kindlegem": 10,
            "Glacial Buckler": 10,
            "Lost Chapter": 10,
            "Fiendish Codex": 10,
            "Caufield's Warhammer": 10,
        ]

        return ahByItem[itemName] ?? 0
    }
}
