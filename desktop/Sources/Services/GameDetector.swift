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

    private let backgroundQueue = DispatchQueue(label: "com.hexlens.gamedetector", qos: .utility)

    func startWatching() {
        guard !isRunning else { return }
        isRunning = true
        // Run process detection on the main run loop timer.
        // checkForProcess uses Process() which blocks briefly (~20ms),
        // but this is more reliable than dispatching to a background queue.
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkForProcess()
        }
        // Check immediately on start
        checkForProcess()
        logger.info("GameDetector: timer scheduled, initial check complete")
    }

    func stopWatching() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private var wasRunning = false

    /// Reset detection state so the next check re-triggers onProcessFound.
    /// Called when LCU connection is permanently lost while LoL is still running.
    func resetWasRunning() {
        wasRunning = false
    }

    private func debugLog(_ msg: String) {
        let line = "[\(Date())] [GameDetector] \(msg)\n"
        if let data = line.data(using: .utf8) {
            let logFile = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("hexlens-debug.log")
            if FileManager.default.fileExists(atPath: logFile.path) {
                let handle = try? FileHandle(forWritingTo: logFile)
                handle?.seekToEndOfFile()
                handle?.write(data)
                handle?.closeFile()
            } else {
                try? data.write(to: logFile)
            }
        }
    }

    private func checkForProcess() {
        let isLolRunning = isLeagueClientRunning()
        debugLog("checkForProcess: isLolRunning=\(isLolRunning), wasRunning=\(wasRunning)")

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
        // Use pgrep instead of ps -A to avoid pipe buffer deadlock.
        // ps -A output can exceed 64KB (Riot's processes have huge args),
        // causing waitUntilExit() to deadlock when the pipe buffer fills.
        let pipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-f", "LeagueClient"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            // Read data BEFORE waitUntilExit to prevent pipe buffer deadlock
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            // pgrep exits 0 if matches found, 1 if not
            return process.terminationStatus == 0 && !data.isEmpty
        } catch {
            logger.error("Failed to run pgrep: \(error.localizedDescription)")
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
