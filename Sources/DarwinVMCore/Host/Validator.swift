import Foundation
import Virtualization

public struct Validator: Sendable {
    public static func validateCPU(_ count: Int, host: HostInfo) throws {
        guard count >= 1 else {
            throw DarwinVMError.validationFailed("CPU count must be at least 1")
        }
        guard count <= host.processorCount else {
            throw DarwinVMError.validationFailed(
                "CPU count \(count) exceeds host processor count (\(host.processorCount))")
        }
    }

    public static func validateMemory(_ gb: Int, host: HostInfo) throws {
        guard gb >= 4 else {
            throw DarwinVMError.validationFailed("Memory must be at least 4 GB")
        }
        let maxGB = Int(host.physicalMemoryGB * 0.8)
        guard gb <= maxGB else {
            throw DarwinVMError.validationFailed(
                "Memory \(gb) GB exceeds 80% of host RAM (\(maxGB) GB)")
        }
        let requestedBytes = UInt64(gb) * 1024 * 1024 * 1024
        let frameworkMax = VZVirtualMachineConfiguration.maximumAllowedMemorySize
        guard requestedBytes <= frameworkMax else {
            throw DarwinVMError.validationFailed(
                "Memory \(gb) GB exceeds Virtualization.framework maximum (\(frameworkMax / 1024 / 1024 / 1024) GB)")
        }
    }

    public static func validateDisk(_ gb: Int, host: HostInfo) throws {
        guard gb >= 1 else {
            throw DarwinVMError.validationFailed("Disk size must be at least 1 GB")
        }
        let maxGB = Int(host.freeDiskSpaceGB * 0.9)
        guard gb <= maxGB else {
            throw DarwinVMError.validationFailed(
                "Disk size \(gb) GB exceeds 90% of free disk space (\(maxGB) GB)")
        }
    }

    public static func validateAll(cpu: Int, memGB: Int, diskGB: Int) throws {
        let host = try HostInfo.current()
        try validateCPU(cpu, host: host)
        try validateMemory(memGB, host: host)
        try validateDisk(diskGB, host: host)
    }
}
