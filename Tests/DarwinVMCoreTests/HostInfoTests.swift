import Testing
@testable import DarwinVMCore

@Suite("HostInfo Tests")
struct HostInfoTests {
    @Test("Current host info returns valid values")
    func currentHostInfo() throws {
        let info = try HostInfo.current()
        #expect(info.processorCount >= 1)
        #expect(info.physicalMemoryBytes > 0)
        #expect(info.physicalMemoryGB >= 1.0)
        #expect(info.freeDiskSpaceBytes > 0)
        #expect(info.freeDiskSpaceGB > 0)
    }
}
