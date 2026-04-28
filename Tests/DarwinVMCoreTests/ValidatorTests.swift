import Testing
@testable import DarwinVMCore

@Suite("Validator Tests")
struct ValidatorTests {
    let host = HostInfo(
        processorCount: 10,
        physicalMemoryBytes: 32 * 1024 * 1024 * 1024,   // 32 GB
        freeDiskSpaceBytes: 200 * 1024 * 1024 * 1024     // 200 GB
    )

    @Test("CPU validation accepts valid count")
    func cpuValid() throws {
        try Validator.validateCPU(4, host: host)
    }

    @Test("CPU validation rejects zero")
    func cpuZero() {
        #expect(throws: DarwinVMError.self) {
            try Validator.validateCPU(0, host: host)
        }
    }

    @Test("CPU validation rejects exceeding host count")
    func cpuExceedsHost() {
        #expect(throws: DarwinVMError.self) {
            try Validator.validateCPU(20, host: host)
        }
    }

    @Test("Memory validation accepts valid GB")
    func memValid() throws {
        try Validator.validateMemory(8, host: host)
    }

    @Test("Memory validation rejects below minimum")
    func memBelowMin() {
        #expect(throws: DarwinVMError.self) {
            try Validator.validateMemory(2, host: host)
        }
    }

    @Test("Memory validation rejects exceeding 80% of host RAM")
    func memExceedsHost() {
        #expect(throws: DarwinVMError.self) {
            try Validator.validateMemory(30, host: host)
        }
    }

    @Test("Disk validation accepts valid GB")
    func diskValid() throws {
        try Validator.validateDisk(64, host: host)
    }

    @Test("Disk validation rejects zero")
    func diskZero() {
        #expect(throws: DarwinVMError.self) {
            try Validator.validateDisk(0, host: host)
        }
    }

    @Test("Disk validation rejects exceeding 90% of free space")
    func diskExceedsFree() {
        #expect(throws: DarwinVMError.self) {
            try Validator.validateDisk(190, host: host)
        }
    }
}
