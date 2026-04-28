import Testing
@testable import DarwinVMCore

@Suite("Validator Tests")
struct ValidatorTests {
    let host = HostInfo(
        processorCount: 10,
        physicalMemoryBytes: 32 * 1024 * 1024 * 1024,   // 32 GB
        freeDiskSpaceBytes: 200 * 1024 * 1024 * 1024     // 200 GB
    )

    // MARK: - CPU Validation

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

    @Test("CPU validation rejects negative")
    func cpuNegative() {
        #expect(throws: DarwinVMError.self) {
            try Validator.validateCPU(-1, host: host)
        }
    }

    @Test("CPU validation rejects exceeding host count")
    func cpuExceedsHost() {
        #expect(throws: DarwinVMError.self) {
            try Validator.validateCPU(20, host: host)
        }
    }

    @Test("CPU validation accepts exactly host count")
    func cpuExactlyHost() throws {
        try Validator.validateCPU(10, host: host)
    }

    @Test("CPU validation accepts 1")
    func cpuOne() throws {
        try Validator.validateCPU(1, host: host)
    }

    // MARK: - Memory Validation

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

    @Test("Memory validation accepts exactly 4 GB minimum")
    func memExactMinimum() throws {
        try Validator.validateMemory(4, host: host)
    }

    @Test("Memory validation accepts boundary value at 80%")
    func memBoundary() throws {
        // Use a smaller host so 80% fits within Virtualization.framework max
        let smallHost = HostInfo(
            processorCount: 10,
            physicalMemoryBytes: 8 * 1024 * 1024 * 1024, // 8 GB
            freeDiskSpaceBytes: 200 * 1024 * 1024 * 1024
        )
        // 80% of 8 GB = 6.4 GB, Int(6.4) = 6
        try Validator.validateMemory(6, host: smallHost)
    }

    // MARK: - Disk Validation

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

    @Test("Disk validation accepts 1 GB minimum")
    func diskMinimum() throws {
        try Validator.validateDisk(1, host: host)
    }

    @Test("Disk validation accepts boundary value at 90%")
    func diskBoundary() throws {
        // 90% of 200 GB = 180 GB
        try Validator.validateDisk(180, host: host)
    }
}
