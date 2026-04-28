import Foundation
import Virtualization

public struct LinuxConfigurator: Sendable {
    @MainActor
    public static func configure(
        config: VMConfig,
        dir: VMDirectory,
        attachISO: Bool = false
    ) throws -> VZVirtualMachineConfiguration {
        let vzConfig = VZVirtualMachineConfiguration()

        // Platform
        let platform = VZGenericPlatformConfiguration()
        if FileManager.default.fileExists(atPath: dir.machineIdentifierURL.path) {
            let idData = try Data(contentsOf: dir.machineIdentifierURL)
            if let machineId = VZGenericMachineIdentifier(dataRepresentation: idData) {
                platform.machineIdentifier = machineId
            }
        }
        vzConfig.platform = platform

        // EFI boot loader with variable store
        let efi: VZEFIBootLoader
        if FileManager.default.fileExists(atPath: dir.nvramURL.path) {
            efi = VZEFIBootLoader()
            efi.variableStore = VZEFIVariableStore(url: dir.nvramURL)
        } else {
            efi = VZEFIBootLoader()
            efi.variableStore = try VZEFIVariableStore(creatingVariableStoreAt: dir.nvramURL)
        }
        vzConfig.bootLoader = efi

        // CPU & Memory
        vzConfig.cpuCount = config.cpuCount
        vzConfig.memorySize = config.memorySize

        // Graphics (VirtIO GPU for Linux)
        let graphics = VZVirtioGraphicsDeviceConfiguration()
        graphics.scanouts = [
            VZVirtioGraphicsScanoutConfiguration(widthInPixels: 1920, heightInPixels: 1080)
        ]
        vzConfig.graphicsDevices = [graphics]

        // Storage
        var storageDevices: [VZStorageDeviceConfiguration] = []
        let disk = try DeviceConfigurator.createDiskAttachment(url: dir.diskURL)
        storageDevices.append(disk)

        // Attach ISO if requested (first boot)
        if attachISO, let isoPath = config.isoPath {
            let isoURL = URL(fileURLWithPath: isoPath)
            if FileManager.default.fileExists(atPath: isoURL.path) {
                let iso = try DeviceConfigurator.createISOAttachment(url: isoURL)
                storageDevices.append(iso)
            }
        }
        vzConfig.storageDevices = storageDevices

        // USB storage for ISO (using USB mass storage for better compatibility)
        // Already handled above via VirtIO block device

        // Network
        vzConfig.networkDevices = NetworkConfigurator.createNetworkDevices(for: config.network)

        // Peripherals
        vzConfig.entropyDevices = [DeviceConfigurator.createEntropyDevice()]
        vzConfig.memoryBalloonDevices = [DeviceConfigurator.createMemoryBalloon()]
        vzConfig.audioDevices = DeviceConfigurator.createAudioDevices()
        vzConfig.keyboards = [VZUSBKeyboardConfiguration()]
        vzConfig.pointingDevices = [VZUSBScreenCoordinatePointingDeviceConfiguration()]
        vzConfig.serialPorts = [DeviceConfigurator.createSerialPort()]

        try vzConfig.validate()
        return vzConfig
    }
}
