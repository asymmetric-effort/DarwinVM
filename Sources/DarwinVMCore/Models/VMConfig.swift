import Foundation

public struct VMConfig: Codable, Sendable {
    public var name: String
    public var type: VMType
    public var cpuCount: Int
    public var memoryGB: Int
    public var diskSizeGB: Int
    public var network: NetworkMode
    public var headless: Bool

    /// Path to IPSW file (macOS only, stored at create time)
    public var ipswPath: String?
    /// Path to ISO file (Linux only, attached on first boot)
    public var isoPath: String?

    public var createdAt: Date

    public init(
        name: String,
        type: VMType,
        cpuCount: Int = 2,
        memoryGB: Int = 4,
        diskSizeGB: Int = 64,
        network: NetworkMode = .nat,
        headless: Bool = false,
        ipswPath: String? = nil,
        isoPath: String? = nil
    ) {
        self.name = name
        self.type = type
        self.cpuCount = cpuCount
        self.memoryGB = memoryGB
        self.diskSizeGB = diskSizeGB
        self.network = network
        self.headless = headless
        self.ipswPath = ipswPath
        self.isoPath = isoPath
        self.createdAt = Date()
    }

    public var memorySize: UInt64 {
        UInt64(memoryGB) * 1024 * 1024 * 1024
    }

    public var diskSize: UInt64 {
        UInt64(diskSizeGB) * 1024 * 1024 * 1024
    }
}
