import XCTest

/// Tests for the GameLifecycleState state machine transitions.
/// Duplicates the transition logic from GameStateManager to test in isolation.
final class GameStateTests: XCTestCase {

    enum State: String {
        case idle, lobby, champSelect, loading, inGame, postGame
    }

    func isValidTransition(from: State, to: State) -> Bool {
        switch (from, to) {
        case (.idle, .lobby), (.idle, .idle): return true
        case (.lobby, .champSelect), (.lobby, .idle): return true
        case (.champSelect, .loading), (.champSelect, .lobby), (.champSelect, .idle): return true
        case (.loading, .inGame), (.loading, .idle): return true
        case (.inGame, .postGame), (.inGame, .idle): return true
        case (.postGame, .idle), (.postGame, .lobby): return true
        default: return false
        }
    }

    // MARK: - Valid Transitions

    func testIdleToLobby() {
        XCTAssertTrue(isValidTransition(from: .idle, to: .lobby))
    }

    func testLobbyToChampSelect() {
        XCTAssertTrue(isValidTransition(from: .lobby, to: .champSelect))
    }

    func testChampSelectToLoading() {
        XCTAssertTrue(isValidTransition(from: .champSelect, to: .loading))
    }

    func testChampSelectDodgeToLobby() {
        XCTAssertTrue(isValidTransition(from: .champSelect, to: .lobby))
    }

    func testLoadingToInGame() {
        XCTAssertTrue(isValidTransition(from: .loading, to: .inGame))
    }

    func testInGameToPostGame() {
        XCTAssertTrue(isValidTransition(from: .inGame, to: .postGame))
    }

    func testPostGameToIdle() {
        XCTAssertTrue(isValidTransition(from: .postGame, to: .idle))
    }

    func testPostGameToLobby() {
        XCTAssertTrue(isValidTransition(from: .postGame, to: .lobby))
    }

    // MARK: - Crash Recovery (any state → idle)

    func testLobbyToIdleCrash() {
        XCTAssertTrue(isValidTransition(from: .lobby, to: .idle))
    }

    func testChampSelectToIdleCrash() {
        XCTAssertTrue(isValidTransition(from: .champSelect, to: .idle))
    }

    func testLoadingToIdleCrash() {
        XCTAssertTrue(isValidTransition(from: .loading, to: .idle))
    }

    func testInGameToIdleCrash() {
        XCTAssertTrue(isValidTransition(from: .inGame, to: .idle))
    }

    // MARK: - Invalid Transitions

    func testIdleToInGameInvalid() {
        XCTAssertFalse(isValidTransition(from: .idle, to: .inGame))
    }

    func testIdleToChampSelectInvalid() {
        XCTAssertFalse(isValidTransition(from: .idle, to: .champSelect))
    }

    func testLobbyToInGameInvalid() {
        XCTAssertFalse(isValidTransition(from: .lobby, to: .inGame))
    }

    func testInGameToChampSelectInvalid() {
        XCTAssertFalse(isValidTransition(from: .inGame, to: .champSelect))
    }

    func testPostGameToInGameInvalid() {
        XCTAssertFalse(isValidTransition(from: .postGame, to: .inGame))
    }

    func testLoadingToLobbyInvalid() {
        XCTAssertFalse(isValidTransition(from: .loading, to: .lobby))
    }

    // MARK: - Full Lifecycle

    func testFullGameLifecycle() {
        let transitions: [(State, State)] = [
            (.idle, .lobby),
            (.lobby, .champSelect),
            (.champSelect, .loading),
            (.loading, .inGame),
            (.inGame, .postGame),
            (.postGame, .idle),
        ]
        for (from, to) in transitions {
            XCTAssertTrue(isValidTransition(from: from, to: to),
                          "Expected valid transition: \(from.rawValue) → \(to.rawValue)")
        }
    }

    func testDodgeLifecycle() {
        let transitions: [(State, State)] = [
            (.idle, .lobby),
            (.lobby, .champSelect),
            (.champSelect, .lobby),      // dodge
            (.lobby, .champSelect),      // re-queue
            (.champSelect, .loading),
            (.loading, .inGame),
            (.inGame, .postGame),
            (.postGame, .idle),
        ]
        for (from, to) in transitions {
            XCTAssertTrue(isValidTransition(from: from, to: to),
                          "Expected valid transition: \(from.rawValue) → \(to.rawValue)")
        }
    }
}
