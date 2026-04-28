import Testing
import Foundation
@testable import DarwinVMCore

@Suite("NetworkMode Tests")
struct NetworkModeTests {
    @Test("Parse 'nat' returns .nat")
    func parseNat() throws {
        let mode = try NetworkMode.parse("nat")
        #expect(mode == .nat)
    }

    @Test("Parse 'bridged:en0' returns .bridged")
    func parseBridged() throws {
        let mode = try NetworkMode.parse("bridged:en0")
        #expect(mode == .bridged(interfaceId: "en0"))
    }

    @Test("Parse 'bridged:' throws for empty interface")
    func parseBridgedEmptyInterface() {
        #expect(throws: DarwinVMError.self) {
            _ = try NetworkMode.parse("bridged:")
        }
    }

    @Test("Parse 'invalid' throws")
    func parseInvalid() {
        #expect(throws: DarwinVMError.self) {
            _ = try NetworkMode.parse("invalid")
        }
    }

    @Test("Parse 'bridged' without colon throws")
    func parseBridgedNoColon() {
        #expect(throws: DarwinVMError.self) {
            _ = try NetworkMode.parse("bridged")
        }
    }

    @Test("JSON encode/decode round-trip for .nat")
    func jsonRoundTripNat() throws {
        let data = try JSONEncoder().encode(NetworkMode.nat)
        let decoded = try JSONDecoder().decode(NetworkMode.self, from: data)
        #expect(decoded == .nat)
    }

    @Test("JSON encode/decode round-trip for .bridged")
    func jsonRoundTripBridged() throws {
        let original = NetworkMode.bridged(interfaceId: "en1")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NetworkMode.self, from: data)
        #expect(decoded == .bridged(interfaceId: "en1"))
    }

    @Test("Equatable conformance: same values are equal")
    func equatable() {
        #expect(NetworkMode.nat == NetworkMode.nat)
        #expect(NetworkMode.bridged(interfaceId: "en0") == NetworkMode.bridged(interfaceId: "en0"))
    }

    @Test("Equatable conformance: different values are not equal")
    func notEquatable() {
        #expect(NetworkMode.nat != NetworkMode.bridged(interfaceId: "en0"))
        #expect(NetworkMode.bridged(interfaceId: "en0") != NetworkMode.bridged(interfaceId: "en1"))
    }
}
