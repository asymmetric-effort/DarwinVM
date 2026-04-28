import Testing
import Foundation
@testable import DarwinVMCore

@Suite("VMDirectory Tests")
struct VMDirectoryTests {
    @Test("Init with name produces correct baseURL under ~/.darwinvm/vms/")
    func initWithName() {
        let dir = VMDirectory(name: "test-vm")
        let home = FileManager.default.homeDirectoryForCurrentUser
        let expected = home.appendingPathComponent(".darwinvm/vms/test-vm")
        #expect(dir.baseURL == expected)
    }

    @Test("Init with custom baseURL works")
    func initWithBaseURL() {
        let url = URL(fileURLWithPath: "/tmp/custom-vm")
        let dir = VMDirectory(baseURL: url)
        #expect(dir.baseURL == url)
    }

    @Test("configURL returns correct filename")
    func configURL() {
        let dir = VMDirectory(baseURL: URL(fileURLWithPath: "/tmp/vm"))
        #expect(dir.configURL.lastPathComponent == "config.json")
    }

    @Test("stateURL returns correct filename")
    func stateURL() {
        let dir = VMDirectory(baseURL: URL(fileURLWithPath: "/tmp/vm"))
        #expect(dir.stateURL.lastPathComponent == "state.json")
    }

    @Test("diskURL returns correct filename")
    func diskURL() {
        let dir = VMDirectory(baseURL: URL(fileURLWithPath: "/tmp/vm"))
        #expect(dir.diskURL.lastPathComponent == "disk.img")
    }

    @Test("pidFileURL returns correct filename")
    func pidFileURL() {
        let dir = VMDirectory(baseURL: URL(fileURLWithPath: "/tmp/vm"))
        #expect(dir.pidFileURL.lastPathComponent == "darwinvm.pid")
    }

    @Test("auxiliaryStorageURL returns correct filename")
    func auxiliaryStorageURL() {
        let dir = VMDirectory(baseURL: URL(fileURLWithPath: "/tmp/vm"))
        #expect(dir.auxiliaryStorageURL.lastPathComponent == "AuxiliaryStorage")
    }

    @Test("hardwareModelURL returns correct filename")
    func hardwareModelURL() {
        let dir = VMDirectory(baseURL: URL(fileURLWithPath: "/tmp/vm"))
        #expect(dir.hardwareModelURL.lastPathComponent == "HardwareModel")
    }

    @Test("machineIdentifierURL returns correct filename")
    func machineIdentifierURL() {
        let dir = VMDirectory(baseURL: URL(fileURLWithPath: "/tmp/vm"))
        #expect(dir.machineIdentifierURL.lastPathComponent == "MachineIdentifier")
    }

    @Test("nvramURL returns correct filename")
    func nvramURL() {
        let dir = VMDirectory(baseURL: URL(fileURLWithPath: "/tmp/vm"))
        #expect(dir.nvramURL.lastPathComponent == "NVRAM.efivars")
    }

    @Test("exists returns false for non-existent directory")
    func existsFalse() {
        let dir = VMDirectory(baseURL: URL(fileURLWithPath: "/tmp/__darwinvm_nonexistent_\(UUID().uuidString)"))
        #expect(dir.exists == false)
    }

    @Test("create() creates directory; exists returns true after")
    func createAndExists() throws {
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("darwinvm_test_\(UUID().uuidString)")
        let dir = VMDirectory(baseURL: tmpURL)
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        #expect(dir.exists == false)
        try dir.create()
        #expect(dir.exists == true)
    }

    @Test("remove() removes directory; exists returns false after")
    func removeAndExists() throws {
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("darwinvm_test_\(UUID().uuidString)")
        let dir = VMDirectory(baseURL: tmpURL)

        try dir.create()
        #expect(dir.exists == true)
        try dir.remove()
        #expect(dir.exists == false)
    }

    @Test("create() is idempotent — calling twice doesn't throw")
    func createIdempotent() throws {
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("darwinvm_test_\(UUID().uuidString)")
        let dir = VMDirectory(baseURL: tmpURL)
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        try dir.create()
        try dir.create() // should not throw
        #expect(dir.exists == true)
    }
}
