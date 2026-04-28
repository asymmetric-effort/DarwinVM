import Testing
import Foundation
@testable import DarwinVMCore

@Suite("VMType Tests")
struct VMTypeTests {
    @Test("macOS raw value is 'macos'")
    func macOSRawValue() {
        #expect(VMType.macOS.rawValue == "macos")
    }

    @Test("linux raw value is 'linux'")
    func linuxRawValue() {
        #expect(VMType.linux.rawValue == "linux")
    }

    @Test("macOS round-trips through JSON")
    func macOSJSONRoundTrip() throws {
        let data = try JSONEncoder().encode(VMType.macOS)
        let decoded = try JSONDecoder().decode(VMType.self, from: data)
        #expect(decoded == .macOS)
    }

    @Test("linux round-trips through JSON")
    func linuxJSONRoundTrip() throws {
        let data = try JSONEncoder().encode(VMType.linux)
        let decoded = try JSONDecoder().decode(VMType.self, from: data)
        #expect(decoded == .linux)
    }

    @Test("Init from raw value 'macos'")
    func initFromMacOS() {
        #expect(VMType(rawValue: "macos") == .macOS)
    }

    @Test("Init from raw value 'linux'")
    func initFromLinux() {
        #expect(VMType(rawValue: "linux") == .linux)
    }

    @Test("Init from invalid raw value returns nil")
    func initFromInvalid() {
        #expect(VMType(rawValue: "windows") == nil)
    }
}
