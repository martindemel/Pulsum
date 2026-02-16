import Foundation
import Network
import Observation

@Observable
@MainActor
public final class NetworkMonitor {
    public private(set) var isConnected: Bool = true

    private nonisolated let monitor = NWPathMonitor()
    private nonisolated let queue = DispatchQueue(label: "ai.pulsum.networkMonitor", qos: .utility)

    public static let shared = NetworkMonitor()

    public init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    nonisolated deinit {
        monitor.cancel()
    }
}
