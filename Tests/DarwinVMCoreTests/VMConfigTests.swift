import Testing
import Foundation
@testable import DarwinVMCore

@Suite("VMConfig Tests")
struct VMConfigTests {
    @Test("Config round-trips through JSON encoding/decoding")
    func configRoundTrip() throws {
        let config = VMConfig(
            name: "test-vm",
            type: .linux,
            cpuCount: 4,
            memoryGB: 8,
            diskSizeGB: 32,
            network: .nat,
            headless: true,
            isoPath: "/tmp/ubuntu.iso"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(config)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(VMConfig.self, from: data)

        #expect(decoded.name == "test-vm")
        #expect(decoded.type == .linux)
        #expect(decoded.cpuCount == 4)
        #expect(decoded.memoryGB == 8)
        #expect(decoded.diskSizeGB == 32)
        #expect(decoded.network == .nat)
        #expect(decoded.headless == true)
        #expect(decoded.isoPath == "/tmp/ubuntu.iso")
        #expect(decoded.ipswPath == nil)
    }

    @Test("Config with bridged network round-trips correctly")
    func bridgedNetworkRoundTrip() throws {
        let config = VMConfig(
            name: "bridged-vm",
            type: .macOS,
            network: .bridged(interfaceId: "en0"),
            ipswPath: "/tmp/restore.ipsw"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(config)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(VMConfig.self, from: data)

        #expect(decoded.name == "bridged-vm")
        #expect(decoded.type == .macOS)
        #expect(decoded.network == .bridged(interfaceId: "en0"))
        #expect(decoded.ipswPath == "/tmp/restore.ipsw")
    }

    @Test("Memory and disk size calculations are correct")
    func sizeCalculations() {
        let config = VMConfig(name: "test", type: .linux, memoryGB: 4, diskSizeGB: 64)
        #expect(config.memorySize == 4 * 1024 * 1024 * 1024)
        #expect(config.diskSize == 64 * 1024 * 1024 * 1024)
    }

    @Test("NetworkMode parsing works correctly")
    func networkModeParsing() throws {
        let nat = try NetworkMode.parse("nat")
        #expect(nat == .nat)

        let bridged = try NetworkMode.parse("bridged:en0")
        #expect(bridged == .bridged(interfaceId: "en0"))
    }

    @Test("NetworkMode parsing rejects invalid input")
    func networkModeInvalid() {
        #expect(throws: DarwinVMError.self) {
            _ = try NetworkMode.parse("invalid")
        }
        #expect(throws: DarwinVMError.self) {
            _ = try NetworkMode.parse("bridged:")
        }
    }
}
