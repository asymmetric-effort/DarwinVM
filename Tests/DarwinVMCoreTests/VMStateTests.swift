import Testing
import Foundation
@testable import DarwinVMCore

@Suite("VMState Tests")
struct VMStateTests {
    @Test("Init sets pid and startedAt")
    func initSetsFields() {
        let before = Date()
        let state = VMState(pid: 42)
        let after = Date()
        #expect(state.pid == 42)
        #expect(state.startedAt >= before)
        #expect(state.startedAt <= after)
    }

    @Test("isRunning returns true for current process PID")
    func isRunningForCurrentProcess() {
        let pid = ProcessInfo.processInfo.processIdentifier
        let state = VMState(pid: pid)
        #expect(state.isRunning == true)
    }

    @Test("isRunning returns false for dead PID")
    func isRunningForDeadPID() {
        // PID 99999 is very unlikely to be running
        let state = VMState(pid: 99999)
        #expect(state.isRunning == false)
    }

    @Test("JSON round-trip preserves values")
    func jsonRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let original = VMState(pid: 12345)
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(VMState.self, from: data)

        #expect(decoded.pid == original.pid)
        // Compare with 1-second tolerance since ISO 8601 may lose sub-second precision
        #expect(abs(decoded.startedAt.timeIntervalSince(original.startedAt)) < 1.0)
    }
}
