import Foundation
import Starscream
import os

/// Data extracted from the League Client lockfile
struct LockfileData {
    let processId: String
    let port: Int
    let password: String
    let protocol_: String
}

/// WebSocket client for the League Client Update (LCU) API.
/// Connects via wss://riot:{password}@127.0.0.1:{port}
///
/// Events:
///   - champ select start/update → onChampSelect
///   - champ select end (game start) → onChampSelectEnd
///   - dodge/remake → onDodge
class LCUClient: NSObject {
    private let logger = Logger(subsystem: "com.macleagueoverlay", category: "LCUClient")
    private let lockfileData: LockfileData
    private var socket: WebSocket?
    private var isConnected = false
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10

    var onChampSelect: ((ChampSelectSession) -> Void)?
    var onChampSelectEnd: (() -> Void)?
    var onDodge: (() -> Void)?

    init(lockfileData: LockfileData) {
        self.lockfileData = lockfileData
        super.init()
    }

    func connect() {
        let urlString = "wss://127.0.0.1:\(lockfileData.port)/"
        guard let url = URL(string: urlString) else {
            logger.error("Invalid LCU URL: \(urlString)")
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        // Basic auth: riot:{password}
        let credentials = "riot:\(lockfileData.password)"
        if let credData = credentials.data(using: .utf8) {
            request.setValue("Basic \(credData.base64EncodedString())", forHTTPHeaderField: "Authorization")
        }

        let engine = WSEngine(transport: TCPTransport())
        socket = WebSocket(request: request, engine: engine)
        socket?.delegate = self
        socket?.connect()

        logger.info("Connecting to LCU on port \(self.lockfileData.port)")
    }

    func disconnect() {
        socket?.disconnect()
        socket = nil
        isConnected = false
    }

    /// Write a rune page to the LoL client via HTTP
    func importRunes(_ page: RunePage, completion: @escaping (Result<Void, Error>) -> Void) {
        let urlString = "https://127.0.0.1:\(lockfileData.port)/lol-perks/v1/pages"
        guard let url = URL(string: urlString) else {
            completion(.failure(LCUError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let credentials = "riot:\(lockfileData.password)"
        if let credData = credentials.data(using: .utf8) {
            request.setValue("Basic \(credData.base64EncodedString())", forHTTPHeaderField: "Authorization")
        }

        do {
            request.httpBody = try JSONEncoder().encode(page)
        } catch {
            completion(.failure(error))
            return
        }

        // Use a session that trusts the LCU's self-signed cert
        let session = URLSession(configuration: .ephemeral, delegate: LCUCertDelegate(), delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                completion(.failure(LCUError.httpError(httpResponse.statusCode)))
                return
            }
            completion(.success(()))
        }.resume()
    }

    /// Subscribe to LCU events after connection
    private func subscribeToEvents() {
        // Subscribe to champ select events via the LCU WebSocket
        let subscribeMsg = "[5, \"OnJsonApiEvent_lol-champ-select_v1_session\"]"
        socket?.write(string: subscribeMsg)
        logger.info("Subscribed to champ select events")
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }

        // LCU WebSocket messages are JSON arrays: [opcode, event, payload]
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [Any],
              json.count >= 3,
              let eventType = json[1] as? String,
              let payload = json[2] as? [String: Any] else {
            return
        }

        if eventType == "OnJsonApiEvent_lol-champ-select_v1_session" {
            handleChampSelectEvent(payload)
        }
    }

    private func handleChampSelectEvent(_ payload: [String: Any]) {
        guard let eventType = payload["eventType"] as? String,
              let payloadData = payload["data"] else {
            return
        }

        switch eventType {
        case "Create", "Update":
            if let jsonData = try? JSONSerialization.data(withJSONObject: payloadData),
               let session = try? JSONDecoder().decode(ChampSelectSession.self, from: jsonData) {
                onChampSelect?(session)
            }
        case "Delete":
            // Champ select ended (game starting or dodge)
            onChampSelectEnd?()
        default:
            break
        }
    }

    private func attemptReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            logger.error("Max reconnect attempts reached")
            return
        }
        reconnectAttempts += 1
        let delay = min(pow(2.0, Double(reconnectAttempts)), 30.0)
        logger.info("Reconnecting in \(delay)s (attempt \(self.reconnectAttempts))")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.connect()
        }
    }
}

extension LCUClient: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: any WebSocketClient) {
        switch event {
        case .connected:
            isConnected = true
            reconnectAttempts = 0
            logger.info("LCU WebSocket connected")
            subscribeToEvents()
        case .disconnected(let reason, let code):
            isConnected = false
            logger.info("LCU WebSocket disconnected: \(reason) (code: \(code))")
            attemptReconnect()
        case .text(let text):
            handleMessage(text)
        case .error(let error):
            isConnected = false
            logger.error("LCU WebSocket error: \(String(describing: error))")
            attemptReconnect()
        case .cancelled:
            isConnected = false
        default:
            break
        }
    }
}

/// SSL cert delegate for LCU HTTPS calls (localhost only)
class LCUCertDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.host == "127.0.0.1",
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }
}

enum LCUError: Error {
    case invalidURL
    case httpError(Int)
    case notConnected
}
