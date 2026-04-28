import Testing
import Foundation
@testable import DarwinVMCore

@Suite("VMStore Tests")
struct VMStoreTests {
    private func makeTempStore() throws -> (VMStore, URL) {
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("darwinvm_store_test_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpURL, withIntermediateDirectories: true)
        return (VMStore(baseURL: tmpURL), tmpURL)
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private func makeConfig(name: String, type: VMType = .linux) -> VMConfig {
        VMConfig(name: name, type: type, cpuCount: 2, memoryGB: 4, diskSizeGB: 32, network: .nat, headless: true)
    }

    @Test("saveConfig + loadConfig round-trip")
    func saveAndLoadConfig() throws {
        let (store, tmpURL) = try makeTempStore()
        defer { cleanup(tmpURL) }

        let config = makeConfig(name: "round-trip-vm")
        let dir = store.directory(for: config.name)
        try dir.create()
        try store.saveConfig(config)
        let loaded = try store.loadConfig(name: "round-trip-vm")

        #expect(loaded.name == "round-trip-vm")
        #expect(loaded.type == .linux)
        #expect(loaded.cpuCount == 2)
        #expect(loaded.memoryGB == 4)
        #expect(loaded.diskSizeGB == 32)
        #expect(loaded.network == .nat)
        #expect(loaded.headless == true)
    }

    @Test("loadConfig throws vmNotFound for missing VM")
    func loadConfigMissing() throws {
        let (store, tmpURL) = try makeTempStore()
        defer { cleanup(tmpURL) }

        #expect(throws: DarwinVMError.self) {
            _ = try store.loadConfig(name: "nonexistent")
        }
    }

    @Test("exists returns true after save, false before")
    func existsCheck() throws {
        let (store, tmpURL) = try makeTempStore()
        defer { cleanup(tmpURL) }

        #expect(store.exists(name: "check-vm") == false)
        let dir = store.directory(for: "check-vm")
        try dir.create()
        try store.saveConfig(makeConfig(name: "check-vm"))
        #expect(store.exists(name: "check-vm") == true)
    }

    @Test("delete removes the VM directory")
    func deleteVM() throws {
        let (store, tmpURL) = try makeTempStore()
        defer { cleanup(tmpURL) }

        let dir = store.directory(for: "delete-vm")
        try dir.create()
        try store.saveConfig(makeConfig(name: "delete-vm"))
        #expect(store.exists(name: "delete-vm") == true)
        try store.delete(name: "delete-vm")
        #expect(store.exists(name: "delete-vm") == false)
    }

    @Test("delete throws vmNotFound for missing VM")
    func deleteMissing() throws {
        let (store, tmpURL) = try makeTempStore()
        defer { cleanup(tmpURL) }

        #expect(throws: DarwinVMError.self) {
            try store.delete(name: "nonexistent")
        }
    }

    @Test("listAll returns empty for no VMs")
    func listAllEmpty() throws {
        let (store, tmpURL) = try makeTempStore()
        defer { cleanup(tmpURL) }

        let configs = try store.listAll()
        #expect(configs.isEmpty)
    }

    @Test("listAll returns sorted configs")
    func listAllSorted() throws {
        let (store, tmpURL) = try makeTempStore()
        defer { cleanup(tmpURL) }

        for name in ["charlie", "alpha", "bravo"] {
            let dir = store.directory(for: name)
            try dir.create()
            try store.saveConfig(makeConfig(name: name))
        }

        let configs = try store.listAll()
        #expect(configs.count == 3)
        #expect(configs[0].name == "alpha")
        #expect(configs[1].name == "bravo")
        #expect(configs[2].name == "charlie")
    }

    @Test("listAll skips directories without config.json")
    func listAllSkipsMissingConfig() throws {
        let (store, tmpURL) = try makeTempStore()
        defer { cleanup(tmpURL) }

        // Create a VM with config
        let dir1 = store.directory(for: "valid-vm")
        try dir1.create()
        try store.saveConfig(makeConfig(name: "valid-vm"))

        // Create a directory without config.json
        let dir2 = store.directory(for: "no-config-vm")
        try dir2.create()

        let configs = try store.listAll()
        #expect(configs.count == 1)
        #expect(configs[0].name == "valid-vm")
    }

    @Test("listAll skips corrupted config.json files")
    func listAllSkipsCorrupted() throws {
        let (store, tmpURL) = try makeTempStore()
        defer { cleanup(tmpURL) }

        // Create a valid VM
        let dir1 = store.directory(for: "good-vm")
        try dir1.create()
        try store.saveConfig(makeConfig(name: "good-vm"))

        // Create a VM with corrupted config
        let dir2 = store.directory(for: "bad-vm")
        try dir2.create()
        try Data("not json".utf8).write(to: dir2.configURL, options: .atomic)

        let configs = try store.listAll()
        #expect(configs.count == 1)
        #expect(configs[0].name == "good-vm")
    }

    @Test("saveState + loadState round-trip")
    func saveAndLoadState() throws {
        let (store, tmpURL) = try makeTempStore()
        defer { cleanup(tmpURL) }

        let dir = store.directory(for: "state-vm")
        try dir.create()

        let state = VMState(pid: 12345)
        try store.saveState(state, name: "state-vm")
        let loaded = store.loadState(name: "state-vm")

        #expect(loaded != nil)
        #expect(loaded?.pid == 12345)
    }

    @Test("loadState returns nil for missing state")
    func loadStateMissing() throws {
        let (store, tmpURL) = try makeTempStore()
        defer { cleanup(tmpURL) }

        let result = store.loadState(name: "nonexistent")
        #expect(result == nil)
    }

    @Test("removeState cleans up state file")
    func removeState() throws {
        let (store, tmpURL) = try makeTempStore()
        defer { cleanup(tmpURL) }

        let dir = store.directory(for: "state-vm")
        try dir.create()
        try store.saveState(VMState(pid: 42), name: "state-vm")

        #expect(store.loadState(name: "state-vm") != nil)
        store.removeState(name: "state-vm")
        #expect(store.loadState(name: "state-vm") == nil)
    }
}
