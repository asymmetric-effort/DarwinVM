import Foundation

/// Filesystem layout for a single VM at ~/.darwinvm/vms/<name>/
public struct VMDirectory: Sendable {
    public let baseURL: URL

    public init(name: String) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.baseURL = home.appendingPathComponent(".darwinvm/vms/\(name)")
    }

    public init(baseURL: URL) {
        self.baseURL = baseURL
    }

    public var configURL: URL { baseURL.appendingPathComponent("config.json") }
    public var stateURL: URL { baseURL.appendingPathComponent("state.json") }
    public var diskURL: URL { baseURL.appendingPathComponent("disk.img") }
    public var pidFileURL: URL { baseURL.appendingPathComponent("darwinvm.pid") }

    // macOS-specific
    public var auxiliaryStorageURL: URL { baseURL.appendingPathComponent("AuxiliaryStorage") }
    public var hardwareModelURL: URL { baseURL.appendingPathComponent("HardwareModel") }

    // Shared (macOS or Linux)
    public var machineIdentifierURL: URL { baseURL.appendingPathComponent("MachineIdentifier") }

    // Linux-specific
    public var nvramURL: URL { baseURL.appendingPathComponent("NVRAM.efivars") }

    public var exists: Bool {
        FileManager.default.fileExists(atPath: baseURL.path)
    }

    public func create() throws {
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    public func remove() throws {
        try FileManager.default.removeItem(at: baseURL)
    }
}
