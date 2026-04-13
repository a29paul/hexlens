import Foundation
import os

/// HTTP client for the League of Legends Live Client Data API.
/// Polls https://127.0.0.1:2999/liveclientdata/allgamedata every 1s.
///
/// The API uses a self-signed SSL certificate. We bypass cert validation
/// ONLY for localhost:2999 via a custom URLSessionDelegate.
class LiveGameClient: NSObject, URLSessionDelegate {
    private let logger = Logger(subsystem: "com.macleagueoverlay", category: "LiveGameClient")
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 5
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private let baseURL = "https://127.0.0.1:2999/liveclientdata"

    func fetchAllGameData(completion: @escaping (Result<LiveGameAllData, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/allgamedata") else {
            completion(.failure(LiveGameError.invalidURL))
            return
        }

        let task = session.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(LiveGameError.noData))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(LiveGameAllData.self, from: data)
                completion(.success(decoded))
            } catch {
                // Log the raw response for debugging API schema changes
                let bodyPreview = String(data: data.prefix(500), encoding: .utf8) ?? "non-utf8"
                self?.logger.error("DecodingError: \(error.localizedDescription). Body preview: \(bodyPreview)")
                completion(.failure(LiveGameError.decodingFailed(underlying: error)))
            }
        }
        task.resume()
    }

    // MARK: - SSL Certificate Bypass (localhost:2999 ONLY)

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Only bypass for Riot's localhost Live Client Data API
        guard challenge.protectionSpace.host == "127.0.0.1",
              challenge.protectionSpace.port == 2999,
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }
}

enum LiveGameError: Error {
    case invalidURL
    case noData
    case decodingFailed(underlying: Error)
    case notInGame
}
