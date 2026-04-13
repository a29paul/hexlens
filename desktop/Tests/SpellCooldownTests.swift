import XCTest

/// Tests for spell cooldown tracking logic.
final class SpellCooldownTests: XCTestCase {

    // Mirror the cooldown lookup from GameStateManager
    func spellBaseCooldown(_ name: String) -> TimeInterval {
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

    // MARK: - Base Cooldowns

    func testFlashCooldown() {
        XCTAssertEqual(spellBaseCooldown("Flash"), 300)
    }

    func testTeleportCooldown() {
        XCTAssertEqual(spellBaseCooldown("Teleport"), 360)
    }

    func testIgniteCooldown() {
        XCTAssertEqual(spellBaseCooldown("Ignite"), 180)
    }

    func testSmiteCooldown() {
        XCTAssertEqual(spellBaseCooldown("Smite"), 90)
    }

    func testUnknownSpellDefaultsTo300() {
        XCTAssertEqual(spellBaseCooldown("UnknownSpell"), 300)
    }

    func testCaseInsensitive() {
        XCTAssertEqual(spellBaseCooldown("FLASH"), 300)
        XCTAssertEqual(spellBaseCooldown("flash"), 300)
        XCTAssertEqual(spellBaseCooldown("Flash"), 300)
    }

    // MARK: - Cooldown State

    struct SpellState {
        var cooldownEnd: Date?
        var baseCooldown: TimeInterval

        var isReady: Bool {
            guard let end = cooldownEnd else { return true }
            return Date() >= end
        }

        var displayText: String {
            if isReady { return "✓" }
            guard let end = cooldownEnd else { return "✓" }
            let remaining = Int(end.timeIntervalSinceNow)
            if remaining <= 0 { return "✓" }
            return "\(remaining)s"
        }

        mutating func markUsed() {
            cooldownEnd = Date().addingTimeInterval(baseCooldown)
        }
    }

    func testSpellReadyByDefault() {
        let spell = SpellState(cooldownEnd: nil, baseCooldown: 300)
        XCTAssertTrue(spell.isReady)
        XCTAssertEqual(spell.displayText, "✓")
    }

    func testSpellOnCooldown() {
        let spell = SpellState(
            cooldownEnd: Date().addingTimeInterval(120),
            baseCooldown: 300
        )
        XCTAssertFalse(spell.isReady)
        // Display should show seconds remaining
        let display = spell.displayText
        XCTAssertTrue(display.hasSuffix("s"), "Expected seconds display, got: \(display)")
    }

    func testSpellCooldownExpired() {
        let spell = SpellState(
            cooldownEnd: Date().addingTimeInterval(-1),
            baseCooldown: 300
        )
        XCTAssertTrue(spell.isReady)
        XCTAssertEqual(spell.displayText, "✓")
    }

    func testMarkUsedStartsCooldown() {
        var spell = SpellState(cooldownEnd: nil, baseCooldown: 300)
        XCTAssertTrue(spell.isReady)

        spell.markUsed()
        XCTAssertFalse(spell.isReady)
    }

    func testMarkUsedSetsCorrectDuration() {
        var spell = SpellState(cooldownEnd: nil, baseCooldown: 180) // Ignite
        spell.markUsed()

        guard let end = spell.cooldownEnd else {
            XCTFail("cooldownEnd should be set")
            return
        }

        let remaining = end.timeIntervalSinceNow
        // Should be approximately 180 seconds (±1s for test execution time)
        XCTAssertTrue(remaining > 178 && remaining <= 180,
                      "Expected ~180s remaining, got \(remaining)")
    }

    // MARK: - Debounce Logic

    func testDebounce() {
        let debounceInterval: TimeInterval = 0.5
        var lastPress: Date? = nil

        func shouldProcess() -> Bool {
            let now = Date()
            if let last = lastPress, now.timeIntervalSince(last) < debounceInterval {
                return false
            }
            lastPress = now
            return true
        }

        // First press should process
        XCTAssertTrue(shouldProcess())

        // Immediate second press should be debounced
        XCTAssertFalse(shouldProcess())
    }
}
