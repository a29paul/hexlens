import XCTest

/// Tests for lockfile parsing logic (from GameDetector).
/// Lockfile format: {processName}:{pid}:{port}:{password}:{protocol}
final class LockfileParsingTests: XCTestCase {

    struct LockfileData {
        let processId: String
        let port: Int
        let password: String
        let protocol_: String
    }

    func parseLockfile(_ contents: String) -> LockfileData? {
        let parts = contents.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ":")
        guard parts.count >= 5,
              let port = Int(parts[2]) else {
            return nil
        }
        return LockfileData(
            processId: String(parts[1]),
            port: port,
            password: String(parts[3]),
            protocol_: String(parts[4])
        )
    }

    // MARK: - Happy Path

    func testValidLockfile() {
        let contents = "LeagueClient:12345:54321:mypassword123:https"
        let result = parseLockfile(contents)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.processId, "12345")
        XCTAssertEqual(result?.port, 54321)
        XCTAssertEqual(result?.password, "mypassword123")
        XCTAssertEqual(result?.protocol_, "https")
    }

    func testLockfileWithTrailingNewline() {
        let contents = "LeagueClient:12345:54321:pass:https\n"
        let result = parseLockfile(contents)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.port, 54321)
    }

    func testLockfileWithCarriageReturn() {
        let contents = "LeagueClient:12345:54321:pass:https\r\n"
        let result = parseLockfile(contents)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.port, 54321)
    }

    func testLockfileWithLongPassword() {
        let contents = "LeagueClient:99999:8080:aVeryLongPasswordThatRiotGenerates1234567890abcdef:https"
        let result = parseLockfile(contents)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.password, "aVeryLongPasswordThatRiotGenerates1234567890abcdef")
    }

    // MARK: - Error Cases

    func testEmptyString() {
        let result = parseLockfile("")
        XCTAssertNil(result)
    }

    func testTooFewParts() {
        let result = parseLockfile("LeagueClient:12345")
        XCTAssertNil(result)
    }

    func testNonNumericPort() {
        let result = parseLockfile("LeagueClient:12345:notaport:pass:https")
        XCTAssertNil(result)
    }

    func testWhitespaceOnly() {
        let result = parseLockfile("   \n  ")
        XCTAssertNil(result)
    }

    func testFourParts() {
        let result = parseLockfile("a:b:1234:d")
        XCTAssertNil(result)
    }

    // MARK: - Edge Cases

    func testExtraColons() {
        // Passwords could theoretically contain colons. With split, parts.count > 5.
        let contents = "LeagueClient:12345:54321:pass:with:colons:https"
        let result = parseLockfile(contents)
        // Should still parse first 5 fields correctly
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.port, 54321)
        XCTAssertEqual(result?.password, "pass")
    }

    func testZeroPort() {
        let contents = "LeagueClient:12345:0:pass:https"
        let result = parseLockfile(contents)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.port, 0)
    }
}
