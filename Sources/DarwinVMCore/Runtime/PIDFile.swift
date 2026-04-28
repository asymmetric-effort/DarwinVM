import Foundation

public struct PIDFile: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func write() throws {
        let pid = ProcessInfo.processInfo.processIdentifier
        let data = Data("\(pid)".utf8)
        try data.write(to: url, options: .atomic)
    }

    public func read() -> Int32? {
        guard let data = try? Data(contentsOf: url),
              let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let pid = Int32(str) else {
            return nil
        }
        return pid
    }

    public func remove() {
        try? FileManager.default.removeItem(at: url)
    }

    /// Check if the process recorded in the PID file is alive.
    public var isProcessRunning: Bool {
        guard let pid = read() else { return false }
        return kill(pid, 0) == 0
    }
}
