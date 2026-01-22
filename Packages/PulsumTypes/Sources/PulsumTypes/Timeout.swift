import Foundation

public enum HardTimeoutResult<T: Sendable>: Sendable {
    case value(T)
    case timedOut
}

public enum HardTimeoutError: LocalizedError, Sendable {
    case timedOut(seconds: Double)

    public var errorDescription: String? {
        switch self {
        case .timedOut(let seconds):
            return String(format: "Operation timed out after %.3f seconds.", seconds)
        }
    }
}

/// Runs `operation` with a hard timeout that returns immediately once the timeout elapses.
/// The underlying task is cancelled on timeout, but the caller does not wait for it to finish,
/// so non-cooperative tasks cannot stall the caller.
public func withHardTimeout<T: Sendable>(seconds: Double,
                                         operation: @escaping @Sendable () async throws -> T) async throws -> HardTimeoutResult<T> {
    let deadlineNanos = UInt64(max(0, seconds) * 1_000_000_000)
    return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HardTimeoutResult<T>, Error>) in
        let coordinator = HardTimeoutCoordinator(continuation: continuation)

        let operationTask = Task { @Sendable in
            do {
                let value = try await operation()
                coordinator.resumeValue(value)
            } catch is CancellationError {
                coordinator.resumeCancellation()
            } catch {
                coordinator.resumeError(error)
            }
        }
        coordinator.setOperationTask(operationTask)

        Task { @Sendable in
            try? await Task.sleep(nanoseconds: deadlineNanos)
            coordinator.resumeTimeout()
        }
    }
}

private final class HardTimeoutCoordinator<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var finished = false
    private var operationTask: Task<Void, Never>?
    private let continuation: CheckedContinuation<HardTimeoutResult<T>, Error>

    init(continuation: CheckedContinuation<HardTimeoutResult<T>, Error>) {
        self.continuation = continuation
    }

    func setOperationTask(_ task: Task<Void, Never>) {
        lock.lock()
        operationTask = task
        lock.unlock()
    }

    func resumeValue(_ value: T) {
        guard markFinished() else { return }
        continuation.resume(returning: .value(value))
    }

    func resumeError(_ error: Error) {
        guard markFinished() else { return }
        continuation.resume(throwing: error)
    }

    func resumeCancellation() {
        guard markFinished() else { return }
        continuation.resume(throwing: CancellationError())
    }

    func resumeTimeout() {
        let task: Task<Void, Never>?
        lock.lock()
        if finished {
            task = nil
            lock.unlock()
            return
        }
        finished = true
        task = operationTask
        lock.unlock()

        task?.cancel()
        continuation.resume(returning: .timedOut)
    }

    private func markFinished() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if finished {
            return false
        }
        finished = true
        return true
    }
}
