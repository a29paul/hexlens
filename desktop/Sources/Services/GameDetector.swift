import Foundation
import os

/// Detects the League of Legends client process and reads its lockfile
/// to extract authentication credentials for the LCU API.
///
/// The lockfile lives at:
///   {LoL install path}/Contents/LoL/lockfile
/// Format: {processName}:{pid}:{port}:{password}:{protocol}
class GameDetector {
    private let logger = Logger(subsystem: "com.macleagueoverlay", category: "GameDetector")
    private var timer: Timer?
    private var isRunning = false

    var onProcessFound: ((LockfileData) -> Void)?
    var onProcessLost: (() -> Void)?

    private let searchPaths = [
        "/Applications/League of Legends.app",
        NSHomeDirectory() + "/Applications/League of Legends.app",
    ]

    func startWatching() {
        guard !isRunning else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkForProcess()
        }
        // Check immediately on start
        checkForProcess()
    }

    func stopWatching() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private var wasRunning = false

    private func checkForProcess() {
        let isLolRunning = isLeagueClientRunning()

        if isLolRunning && !wasRunning {
            logger.info("LoL client detected")
            if let lockfile = readLockfile() {
                onProcessFound?(lockfile)
            } else {
                logger.warning("LoL running but lockfile not found")
            }
        } else if !isLolRunning && wasRunning {
            logger.info("LoL client closed")
            onProcessLost?()
        }

        wasRunning = isLolRunning
    }

    private func isLeagueClientRunning() -> Bool {
        let pipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-A"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return output.contains("LeagueClientUx") || output.contains("LeagueClient")
        } catch {
            logger.error("Failed to run ps: \(error.localizedDescription)")
            return false
        }
    }

    private func readLockfile() -> LockfileData? {
        // Check user-configured path first
        let customPath = UserDefaults.standard.string(forKey: "lolInstallPath")
            ?? "/Applications/League of Legends.app"

        let allPaths = [customPath] + searchPaths
        let uniquePaths = allPaths.reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }

        for basePath in uniquePaths {
            let lockfilePath = "\(basePath)/Contents/LoL/lockfile"
            if let contents = try? String(contentsOfFile: lockfilePath, encoding: .utf8) {
                return parseLockfile(contents)
            }
        }

        logger.warning("Lockfile not found in any search path")
        return nil
    }

    private func parseLockfile(_ contents: String) -> LockfileData? {
        let parts = contents.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ":")
        guard parts.count >= 5,
              let port = Int(parts[2]) else {
            logger.error("Failed to parse lockfile: unexpected format")
            return nil
        }

        let data = LockfileData(
            processId: String(parts[1]),
            port: port,
            password: String(parts[3]),
            protocol_: String(parts[4])
        )
        logger.info("Lockfile parsed: port=\(data.port)")
        return data
    }
}
