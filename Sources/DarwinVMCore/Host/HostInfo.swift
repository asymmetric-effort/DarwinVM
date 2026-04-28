import Foundation

public struct HostInfo: Sendable {
    public let processorCount: Int
    public let physicalMemoryBytes: UInt64
    public let freeDiskSpaceBytes: UInt64

    public var physicalMemoryGB: Double {
        Double(physicalMemoryBytes) / (1024 * 1024 * 1024)
    }

    public var freeDiskSpaceGB: Double {
        Double(freeDiskSpaceBytes) / (1024 * 1024 * 1024)
    }

    public static func current() throws -> HostInfo {
        let cpuCount = ProcessInfo.processInfo.processorCount
        let totalRAM = ProcessInfo.processInfo.physicalMemory

        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let values = try homeURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        let freeSpace = UInt64(values.volumeAvailableCapacityForImportantUsage ?? 0)

        return HostInfo(
            processorCount: cpuCount,
            physicalMemoryBytes: totalRAM,
            freeDiskSpaceBytes: freeSpace
        )
    }
}
