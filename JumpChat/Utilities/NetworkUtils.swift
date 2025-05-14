import Foundation
import Network

public enum NetworkError: Error, Equatable {
    case offline
    case timeout
    case other(String)

    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.offline, .offline):
            return true
        case (.timeout, .timeout):
            return true
        case (.other(let lMsg), .other(let rMsg)):
            return lMsg == rMsg
        default:
            return false
        }
    }
}

public class NetworkUtils {
    private static let monitor = NWPathMonitor()
    private static let queue = DispatchQueue(label: "com.jumpchat.networkutils.monitor", qos: .background)
    private static var _isCurrentlyConnected: Bool = false
    private static var isInitialized = false

    private init() {}

    public static func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
        
        monitor.pathUpdateHandler = { path in
            let newStatus = path.status == .satisfied
            if _isCurrentlyConnected != newStatus {
                _isCurrentlyConnected = newStatus
            }
        }
        monitor.start(queue: queue)
    }

    public static func isConnected() -> Bool {
        guard isInitialized else {
            print("[NetworkUtils] Warning: NetworkUtils not initialized. Call NetworkUtils.initialize() first. Defaulting to offline status.")
            return false
        }
        return _isCurrentlyConnected
    }

    public static func stopMonitoring() {
        guard isInitialized else { return }
        monitor.cancel()
        isInitialized = false
        _isCurrentlyConnected = false
    }
}
