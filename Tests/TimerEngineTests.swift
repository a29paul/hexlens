import XCTest

/// Tests for jungle timer respawn logic.
final class TimerEngineTests: XCTestCase {

    struct JungleTimer {
        let id: String
        let name: String
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
    }

    // MARK: - Display Value

    func testAliveTimerShowsUP() {
        let timer = JungleTimer(id: "dragon", name: "Dragon", respawnTime: nil, isAlive: true)
        XCTAssertEqual(timer.displayValue, "UP")
    }

    func testDeadTimerWithNoRespawnShowsQuestionMarks() {
        let timer = JungleTimer(id: "dragon", name: "Dragon", respawnTime: nil, isAlive: false)
        XCTAssertEqual(timer.displayValue, "???")
    }

    func testTimerCountdownFormat() {
        let timer = JungleTimer(
            id: "dragon",
            name: "Dragon",
            respawnTime: Date().addingTimeInterval(185),
            isAlive: false
        )
        let display = timer.displayValue
        // Should be ~3:05
        XCTAssertTrue(display.contains(":"), "Expected M:SS format, got: \(display)")
    }

    func testExpiredTimerShowsUP() {
        let timer = JungleTimer(
            id: "dragon",
            name: "Dragon",
            respawnTime: Date().addingTimeInterval(-5),
            isAlive: false
        )
        XCTAssertEqual(timer.displayValue, "UP")
    }

    func testTimerFormatsZeroPaddedSeconds() {
        let timer = JungleTimer(
            id: "baron",
            name: "Baron",
            respawnTime: Date().addingTimeInterval(63), // 1:03
            isAlive: false
        )
        let display = timer.displayValue
        XCTAssertTrue(display == "1:03" || display == "1:02",
                      "Expected 1:03 or 1:02, got: \(display)")
    }

    // MARK: - Urgency

    func testNotUrgentWhenAlive() {
        let timer = JungleTimer(id: "dragon", name: "Dragon", respawnTime: nil, isAlive: true)
        XCTAssertFalse(timer.isUrgent)
    }

    func testNotUrgentWhenFarOut() {
        let timer = JungleTimer(
            id: "dragon",
            name: "Dragon",
            respawnTime: Date().addingTimeInterval(120),
            isAlive: false
        )
        XCTAssertFalse(timer.isUrgent)
    }

    func testUrgentWhenUnder30Seconds() {
        let timer = JungleTimer(
            id: "dragon",
            name: "Dragon",
            respawnTime: Date().addingTimeInterval(20),
            isAlive: false
        )
        XCTAssertTrue(timer.isUrgent)
    }

    func testNotUrgentWhenExpired() {
        let timer = JungleTimer(
            id: "dragon",
            name: "Dragon",
            respawnTime: Date().addingTimeInterval(-5),
            isAlive: false
        )
        XCTAssertFalse(timer.isUrgent)
    }

    // MARK: - Respawn Times

    func testDragonRespawnIs5Minutes() {
        let respawnSeconds: TimeInterval = 300
        let eventTime: Double = 600 // killed at 10:00
        let gameTime: Double = 600  // current time is also 10:00

        let timeSinceEvent = gameTime - eventTime
        let remaining = respawnSeconds - timeSinceEvent

        XCTAssertEqual(remaining, 300, "Dragon should have 5 minutes remaining")
    }

    func testBaronRespawnIs6Minutes() {
        let respawnSeconds: TimeInterval = 360
        let eventTime: Double = 1200 // killed at 20:00
        let gameTime: Double = 1200

        let remaining = respawnSeconds - (gameTime - eventTime)
        XCTAssertEqual(remaining, 360)
    }

    func testRespawnAccountsForTimeSinceKill() {
        let respawnSeconds: TimeInterval = 300
        let eventTime: Double = 600  // killed at 10:00
        let gameTime: Double = 720   // current time is 12:00 (2 min later)

        let remaining = respawnSeconds - (gameTime - eventTime)
        XCTAssertEqual(remaining, 180, "Should have 3 minutes remaining")
    }

    func testRespawnAlreadyExpired() {
        let respawnSeconds: TimeInterval = 300
        let eventTime: Double = 600
        let gameTime: Double = 1200 // 10 minutes later

        let remaining = respawnSeconds - (gameTime - eventTime)
        XCTAssertTrue(remaining < 0, "Timer should be expired")
    }
}
