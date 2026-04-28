import Foundation

/// CRUD operations across all VMs in a base directory.
public struct VMStore: Sendable {
    public let baseURL: URL

    private static let defaultBaseURL: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".darwinvm/vms")
    }()

    /// Shared instance using the default ~/.darwinvm/vms/ base directory.
    public static let shared = VMStore()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    public init(baseURL: URL? = nil) {
        self.baseURL = baseURL ?? VMStore.defaultBaseURL
    }

    public func directory(for name: String) -> VMDirectory {
        VMDirectory(baseURL: baseURL.appendingPathComponent(name))
    }

    public func ensureBaseDirectory() throws {
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    public func saveConfig(_ config: VMConfig) throws {
        let dir = directory(for: config.name)
        let data = try encoder.encode(config)
        try data.write(to: dir.configURL, options: .atomic)
    }

    public func loadConfig(name: String) throws -> VMConfig {
        let dir = directory(for: name)
        guard FileManager.default.fileExists(atPath: dir.configURL.path) else {
            throw DarwinVMError.vmNotFound(name)
        }
        let data = try Data(contentsOf: dir.configURL)
        return try decoder.decode(VMConfig.self, from: data)
    }

    public func saveState(_ state: VMState, name: String) throws {
        let dir = directory(for: name)
        let data = try encoder.encode(state)
        try data.write(to: dir.stateURL, options: .atomic)
    }

    public func loadState(name: String) -> VMState? {
        let dir = directory(for: name)
        guard let data = try? Data(contentsOf: dir.stateURL) else { return nil }
        return try? decoder.decode(VMState.self, from: data)
    }

    public func removeState(name: String) {
        let dir = directory(for: name)
        try? FileManager.default.removeItem(at: dir.stateURL)
    }

    public func listAll() throws -> [VMConfig] {
        try ensureBaseDirectory()
        let contents = try FileManager.default.contentsOfDirectory(
            at: baseURL, includingPropertiesForKeys: nil)
        var configs: [VMConfig] = []
        for dirURL in contents {
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: dirURL.path, isDirectory: &isDir),
                  isDir.boolValue else { continue }
            let configURL = dirURL.appendingPathComponent("config.json")
            guard FileManager.default.fileExists(atPath: configURL.path) else { continue }
            if let data = try? Data(contentsOf: configURL),
               let config = try? decoder.decode(VMConfig.self, from: data) {
                configs.append(config)
            }
        }
        return configs.sorted { $0.name < $1.name }
    }

    public func exists(name: String) -> Bool {
        directory(for: name).exists
    }

    public func delete(name: String) throws {
        let dir = directory(for: name)
        guard dir.exists else {
            throw DarwinVMError.vmNotFound(name)
        }
        try dir.remove()
    }

    // MARK: - Static convenience methods (delegate to shared instance)

    public static func ensureBaseDirectory() throws {
        try shared.ensureBaseDirectory()
    }

    public static func saveConfig(_ config: VMConfig) throws {
        try shared.saveConfig(config)
    }

    public static func loadConfig(name: String) throws -> VMConfig {
        try shared.loadConfig(name: name)
    }

    public static func saveState(_ state: VMState, name: String) throws {
        try shared.saveState(state, name: name)
    }

    public static func loadState(name: String) -> VMState? {
        shared.loadState(name: name)
    }

    public static func removeState(name: String) {
        shared.removeState(name: name)
    }

    public static func listAll() throws -> [VMConfig] {
        try shared.listAll()
    }

    public static func exists(name: String) -> Bool {
        shared.exists(name: name)
    }

    public static func delete(name: String) throws {
        try shared.delete(name: name)
    }
}
