import Foundation

enum AsyncTimeout {
    static func run<T>(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw AsyncTimeoutError()
            }
            guard let result = try await group.next() else {
                throw AsyncTimeoutError()
            }
            group.cancelAll()
            return result
        }
    }
}

struct AsyncTimeoutError: LocalizedError {
    var errorDescription: String? {
        "The operation timed out."
    }
}
