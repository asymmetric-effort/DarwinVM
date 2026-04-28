import Testing
import Foundation
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

    @Test("physicalMemoryGB calculation is correct")
    func memoryGBCalculation() {
        let info = HostInfo(
            processorCount: 8,
            physicalMemoryBytes: 16 * 1024 * 1024 * 1024, // 16 GB
            freeDiskSpaceBytes: 100 * 1024 * 1024 * 1024
        )
        #expect(info.physicalMemoryGB == 16.0)
    }

    @Test("freeDiskSpaceGB calculation is correct")
    func diskGBCalculation() {
        let info = HostInfo(
            processorCount: 8,
            physicalMemoryBytes: 16 * 1024 * 1024 * 1024,
            freeDiskSpaceBytes: 250 * 1024 * 1024 * 1024 // 250 GB
        )
        #expect(info.freeDiskSpaceGB == 250.0)
    }

    @Test("HostInfo can be initialized with custom values")
    func customInit() {
        let info = HostInfo(processorCount: 4, physicalMemoryBytes: 8_589_934_592, freeDiskSpaceBytes: 500_000_000_000)
        #expect(info.processorCount == 4)
        #expect(info.physicalMemoryBytes == 8_589_934_592)
        #expect(info.freeDiskSpaceBytes == 500_000_000_000)
    }
}
