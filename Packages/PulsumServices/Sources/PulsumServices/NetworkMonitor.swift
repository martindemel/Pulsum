import Foundation
import Network
import Observation

@Observable
public final class NetworkMonitor: @unchecked Sendable {
    public private(set) var isConnected: Bool = true

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "ai.pulsum.networkMonitor", qos: .utility)

    public static let shared = NetworkMonitor()

    public init() {
        self.monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
