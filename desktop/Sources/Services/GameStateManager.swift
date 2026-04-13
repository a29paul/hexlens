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
    @Published var champSelectSession: ChampSelectSession?
    @Published var activePlayerName: String = ""

    private let logger = Logger(subsystem: "com.macleagueoverlay", category: "GameState")
    private var gameDetector: GameDetector?
    private var lcuClient: LCUClient?
    private var liveGameClient: LiveGameClient?
    private var timerEngine: TimerEngine?
    private var spellTracker: SpellTracker?
    private var pollTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    func start() {
        gameDetector = GameDetector()
        timerEngine = TimerEngine()
        spellTracker = SpellTracker()

        // Wire spell tracker to update enemy spell cooldowns
        spellTracker?.onSpellUsed = { [weak self] enemyIndex, spellIndex in
            self?.markSpellUsed(enemyIndex: enemyIndex, spellIndex: spellIndex)
        }

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
            spellTracker?.start()
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
        case (.lobby, .champSelect), (.lobby, .idle): return true
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
        lcuClient?.connect()
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

    private func pollLiveGame() {
        liveGameClient?.fetchAllGameData { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
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
        let benchmark = PatchDataService.shared.getCSBenchmark(role: playerRole, gameTimeMinutes: max(gameMinutes, 1))
        csBenchmarkDiff = currentCS - Int(benchmark)

        // Process events for timers
        timerEngine?.processEvents(data.events.Events, gameTime: data.gameData.gameTime)
        jungleTimers = timerEngine?.timers ?? GameStateManager.defaultTimers()

        // Build enemy spell states — only if we know our team
        guard let myTeam = me?.team, !myTeam.isEmpty else { return }
        let enemies = data.allPlayers.filter { $0.team != myTeam }.sorted { $0.summonerName < $1.summonerName }
        enemySpells = enemies.prefix(5).map { enemy in
            let existing = self.enemySpells.first { $0.championName == enemy.championName }
            return EnemySpellState(
                id: enemy.championName,
                championName: enemy.championName,
                spell1: existing?.spell1 ?? SpellCooldownState(
                    spellName: enemy.summonerSpells.summonerSpellOne.displayName,
                    baseCooldown: spellBaseCooldown(enemy.summonerSpells.summonerSpellOne.displayName)
                ),
                spell2: existing?.spell2 ?? SpellCooldownState(
                    spellName: enemy.summonerSpells.summonerSpellTwo.displayName,
                    baseCooldown: spellBaseCooldown(enemy.summonerSpells.summonerSpellTwo.displayName)
                )
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

        // Gold lead (our team total gold vs enemy team total gold)
        let allyGold = data.allPlayers.filter { $0.team == myTeam }
            .reduce(0) { $0 + $1.scores.kills * 300 + $1.scores.assists * 150 + $1.scores.creepScore * 20 }
        let enemyGold = data.allPlayers.filter { $0.team != myTeam }
            .reduce(0) { $0 + $1.scores.kills * 300 + $1.scores.assists * 150 + $1.scores.creepScore * 20 }
        goldLead = allyGold - enemyGold

        // Inhibitor timers from events
        processInhibitorEvents(data.events.Events, gameTime: data.gameData.gameTime)
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
        spellTracker?.stop()
        lcuClient?.disconnect()
        lcuClient = nil
        currentCS = 0
        csBenchmarkDiff = 0
        playerRole = .unknown
        enemySpells = []
        allies = []
        inhibitorTimers = []
        goldLead = 0
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
}
