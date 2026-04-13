import Foundation
import os

/// Tracks jungle objective respawn timers based on in-game events.
///
/// Dragon: 5 min respawn. Baron: 6 min respawn.
/// Buff camps (Blue/Red): 5 min respawn.
class TimerEngine {
    private let logger = Logger(subsystem: "com.macleagueoverlay", category: "TimerEngine")
    private(set) var timers: [JungleTimer] = GameStateManager.defaultTimers()
    private var processedEventIDs: Set<Int> = []

    private let respawnTimes: [String: TimeInterval] = [
        "dragon": 300,   // 5 minutes
        "baron": 360,    // 6 minutes
        "herald": 480,   // 8 minutes (Rift Herald)
    ]

    func processEvents(_ events: [LiveEvents.LiveEvent], gameTime: Double) {
        for event in events {
            guard !processedEventIDs.contains(event.EventID) else { continue }
            processedEventIDs.insert(event.EventID)

            switch event.EventName {
            case "DragonKill":
                setTimer(id: "dragon", respawnSeconds: 300, gameTime: gameTime, eventTime: event.EventTime)
                logger.info("Dragon killed at \(event.EventTime), respawns in 5 min")

            case "BaronKill":
                setTimer(id: "baron", respawnSeconds: 360, gameTime: gameTime, eventTime: event.EventTime)
                logger.info("Baron killed at \(event.EventTime), respawns in 6 min")

            case "HeraldKill":
                // Herald has its own timer slot, not Baron's. Herald respawns once; Baron spawns at 20min.
                // Don't overwrite baron timer with herald data.
                break

            default:
                break
            }
        }
    }

    private func setTimer(id: String, respawnSeconds: TimeInterval, gameTime: Double, eventTime: Double) {
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }

        let timeSinceEvent = gameTime - eventTime
        let remainingRespawn = respawnSeconds - timeSinceEvent

        if remainingRespawn > 0 {
            timers[index].respawnTime = Date().addingTimeInterval(remainingRespawn)
            timers[index].isAlive = false
        } else {
            timers[index].respawnTime = nil
            timers[index].isAlive = true
        }
    }

    func reset() {
        timers = GameStateManager.defaultTimers()
        processedEventIDs.removeAll()
    }
}
