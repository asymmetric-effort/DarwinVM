import Foundation

/// CRUD operations across all VMs in ~/.darwinvm/vms/
public struct VMStore: Sendable {
    private static var baseURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".darwinvm/vms")
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    public static func ensureBaseDirectory() throws {
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    public static func saveConfig(_ config: VMConfig) throws {
        let dir = VMDirectory(name: config.name)
        let data = try encoder.encode(config)
        try data.write(to: dir.configURL, options: .atomic)
    }

    public static func loadConfig(name: String) throws -> VMConfig {
        let dir = VMDirectory(name: name)
        guard FileManager.default.fileExists(atPath: dir.configURL.path) else {
            throw DarwinVMError.vmNotFound(name)
        }
        let data = try Data(contentsOf: dir.configURL)
        return try decoder.decode(VMConfig.self, from: data)
    }

    public static func saveState(_ state: VMState, name: String) throws {
        let dir = VMDirectory(name: name)
        let data = try encoder.encode(state)
        try data.write(to: dir.stateURL, options: .atomic)
    }

    public static func loadState(name: String) -> VMState? {
        let dir = VMDirectory(name: name)
        guard let data = try? Data(contentsOf: dir.stateURL) else { return nil }
        return try? decoder.decode(VMState.self, from: data)
    }

    public static func removeState(name: String) {
        let dir = VMDirectory(name: name)
        try? FileManager.default.removeItem(at: dir.stateURL)
    }

    public static func listAll() throws -> [VMConfig] {
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

    public static func exists(name: String) -> Bool {
        VMDirectory(name: name).exists
    }

    public static func delete(name: String) throws {
        let dir = VMDirectory(name: name)
        guard dir.exists else {
            throw DarwinVMError.vmNotFound(name)
        }
        try dir.remove()
    }
}
