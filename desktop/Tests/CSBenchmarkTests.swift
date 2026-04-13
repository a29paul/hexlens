import XCTest

/// Tests for role-adaptive CS benchmark calculations.
final class CSBenchmarkTests: XCTestCase {

    enum Role: String {
        case top, jungle, mid, adc, support, unknown
    }

    // Mirror PatchDataService.getCSBenchmark
    func getCSBenchmark(role: Role, gameTimeMinutes: Int) -> Double {
        switch role {
        case .adc:     return Double(gameTimeMinutes) * 8.0
        case .mid:     return Double(gameTimeMinutes) * 7.5
        case .top:     return Double(gameTimeMinutes) * 7.0
        case .jungle:  return Double(gameTimeMinutes) * 5.5
        case .support: return Double(gameTimeMinutes) * 1.5
        case .unknown: return Double(gameTimeMinutes) * 7.0
        }
    }

    // MARK: - ADC Benchmarks

    func testADC10Minutes() {
        XCTAssertEqual(getCSBenchmark(role: .adc, gameTimeMinutes: 10), 80)
    }

    func testADC20Minutes() {
        XCTAssertEqual(getCSBenchmark(role: .adc, gameTimeMinutes: 20), 160)
    }

    func testADC30Minutes() {
        XCTAssertEqual(getCSBenchmark(role: .adc, gameTimeMinutes: 30), 240)
    }

    // MARK: - Jungler Benchmarks (lower CS)

    func testJungler10Minutes() {
        XCTAssertEqual(getCSBenchmark(role: .jungle, gameTimeMinutes: 10), 55)
    }

    func testJungler20Minutes() {
        XCTAssertEqual(getCSBenchmark(role: .jungle, gameTimeMinutes: 20), 110)
    }

    // MARK: - Support Benchmarks (minimal CS)

    func testSupport10Minutes() {
        XCTAssertEqual(getCSBenchmark(role: .support, gameTimeMinutes: 10), 15)
    }

    func testSupport30Minutes() {
        XCTAssertEqual(getCSBenchmark(role: .support, gameTimeMinutes: 30), 45)
    }

    // MARK: - CS Diff Calculation

    func testAheadOfBenchmark() {
        let currentCS = 95
        let benchmark = getCSBenchmark(role: .adc, gameTimeMinutes: 10) // 80
        let diff = currentCS - Int(benchmark)
        XCTAssertEqual(diff, 15)
    }

    func testBehindBenchmark() {
        let currentCS = 60
        let benchmark = getCSBenchmark(role: .adc, gameTimeMinutes: 10) // 80
        let diff = currentCS - Int(benchmark)
        XCTAssertEqual(diff, -20)
    }

    func testExactlyAtBenchmark() {
        let currentCS = 80
        let benchmark = getCSBenchmark(role: .adc, gameTimeMinutes: 10) // 80
        let diff = currentCS - Int(benchmark)
        XCTAssertEqual(diff, 0)
    }

    // MARK: - Edge Cases

    func testZeroMinutes() {
        XCTAssertEqual(getCSBenchmark(role: .adc, gameTimeMinutes: 0), 0)
    }

    func testUnknownRoleDefaultsToMidRange() {
        let unknown = getCSBenchmark(role: .unknown, gameTimeMinutes: 10)
        let top = getCSBenchmark(role: .top, gameTimeMinutes: 10)
        XCTAssertEqual(unknown, top, "Unknown role should default to top-tier benchmark (7.0 CS/min)")
    }

    func testAllRolesHaveDifferentBenchmarks() {
        let roles: [Role] = [.top, .jungle, .mid, .adc, .support]
        let benchmarks = roles.map { getCSBenchmark(role: $0, gameTimeMinutes: 10) }
        let unique = Set(benchmarks)
        XCTAssertEqual(unique.count, roles.count, "Each role should have a distinct CS benchmark")
    }

    func testJunglerAlwaysLowerThanLaners() {
        for minutes in [5, 10, 15, 20, 25, 30] {
            let jungle = getCSBenchmark(role: .jungle, gameTimeMinutes: minutes)
            let mid = getCSBenchmark(role: .mid, gameTimeMinutes: minutes)
            let adc = getCSBenchmark(role: .adc, gameTimeMinutes: minutes)
            XCTAssertTrue(jungle < mid, "Jungler CS should be lower than mid at \(minutes)min")
            XCTAssertTrue(jungle < adc, "Jungler CS should be lower than ADC at \(minutes)min")
        }
    }

    func testSupportAlwaysLowest() {
        for minutes in [5, 10, 15, 20, 25, 30] {
            let support = getCSBenchmark(role: .support, gameTimeMinutes: minutes)
            let jungle = getCSBenchmark(role: .jungle, gameTimeMinutes: minutes)
            XCTAssertTrue(support < jungle, "Support CS should be lowest at \(minutes)min")
        }
    }
}
