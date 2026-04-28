import Foundation

public struct VMState: Codable, Sendable {
    public var pid: Int32
    public var startedAt: Date

    public init(pid: Int32) {
        self.pid = pid
        self.startedAt = Date()
    }

    /// Check if the process with the stored PID is still running.
    public var isRunning: Bool {
        kill(pid, 0) == 0
    }
}
