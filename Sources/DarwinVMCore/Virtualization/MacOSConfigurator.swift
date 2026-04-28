import Foundation
import Virtualization

public struct MacOSConfigurator: Sendable {
    @MainActor
    public static func configure(
        config: VMConfig,
        dir: VMDirectory,
        hardwareModel: VZMacHardwareModel,
        machineIdentifier: VZMacMachineIdentifier
    ) throws -> VZVirtualMachineConfiguration {
        let vzConfig = VZVirtualMachineConfiguration()

        // Platform
        let platform = VZMacPlatformConfiguration()
        platform.auxiliaryStorage = try VZMacAuxiliaryStorage(
            creatingStorageAt: dir.auxiliaryStorageURL,
            hardwareModel: hardwareModel,
            options: [])
        platform.hardwareModel = hardwareModel
        platform.machineIdentifier = machineIdentifier
        vzConfig.platform = platform

        // Boot loader
        vzConfig.bootLoader = VZMacOSBootLoader()

        // CPU & Memory
        vzConfig.cpuCount = config.cpuCount
        vzConfig.memorySize = config.memorySize

        // Graphics
        let graphics = VZMacGraphicsDeviceConfiguration()
        graphics.displays = [
            VZMacGraphicsDisplayConfiguration(
                widthInPixels: 1920, heightInPixels: 1200, pixelsPerInch: 144)
        ]
        vzConfig.graphicsDevices = [graphics]

        // Disk
        let disk = try DeviceConfigurator.createDiskAttachment(url: dir.diskURL)
        vzConfig.storageDevices = [disk]

        // Network
        vzConfig.networkDevices = NetworkConfigurator.createNetworkDevices(for: config.network)

        // Peripherals
        vzConfig.entropyDevices = [DeviceConfigurator.createEntropyDevice()]
        vzConfig.memoryBalloonDevices = [DeviceConfigurator.createMemoryBalloon()]
        vzConfig.audioDevices = DeviceConfigurator.createAudioDevices()

        // Keyboard & pointing
        vzConfig.keyboards = [VZUSBKeyboardConfiguration()]
        vzConfig.pointingDevices = [VZUSBScreenCoordinatePointingDeviceConfiguration()]

        // Serial (always add for debugging)
        vzConfig.serialPorts = [DeviceConfigurator.createSerialPort()]

        try vzConfig.validate()
        return vzConfig
    }

    @MainActor
    public static func configureForBoot(
        config: VMConfig,
        dir: VMDirectory
    ) throws -> VZVirtualMachineConfiguration {
        // Load persisted hardware model and machine identifier
        let hardwareModelData = try Data(contentsOf: dir.hardwareModelURL)
        guard let hardwareModel = VZMacHardwareModel(dataRepresentation: hardwareModelData) else {
            throw DarwinVMError.configurationFailed("Invalid hardware model data")
        }

        let machineIdData = try Data(contentsOf: dir.machineIdentifierURL)
        guard let machineIdentifier = VZMacMachineIdentifier(dataRepresentation: machineIdData) else {
            throw DarwinVMError.configurationFailed("Invalid machine identifier data")
        }

        let vzConfig = VZVirtualMachineConfiguration()

        // Platform (use existing auxiliary storage)
        let platform = VZMacPlatformConfiguration()
        platform.auxiliaryStorage = VZMacAuxiliaryStorage(contentsOf: dir.auxiliaryStorageURL)
        platform.hardwareModel = hardwareModel
        platform.machineIdentifier = machineIdentifier
        vzConfig.platform = platform

        vzConfig.bootLoader = VZMacOSBootLoader()
        vzConfig.cpuCount = config.cpuCount
        vzConfig.memorySize = config.memorySize

        let graphics = VZMacGraphicsDeviceConfiguration()
        graphics.displays = [
            VZMacGraphicsDisplayConfiguration(
                widthInPixels: 1920, heightInPixels: 1200, pixelsPerInch: 144)
        ]
        vzConfig.graphicsDevices = [graphics]

        let disk = try DeviceConfigurator.createDiskAttachment(url: dir.diskURL)
        vzConfig.storageDevices = [disk]

        vzConfig.networkDevices = NetworkConfigurator.createNetworkDevices(for: config.network)
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
