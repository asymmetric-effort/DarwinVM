import ArgumentParser
import Foundation
import DarwinVMCore
import Virtualization

struct CreateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new virtual machine"
    )

    @Argument(help: "Name of the virtual machine")
    var name: String

    @Option(help: "VM type: macos or linux")
    var type: String

    @Option(help: "Path to macOS IPSW restore image (macOS only)")
    var ipsw: String?

    @Option(help: "Path to Linux ISO installer image (Linux only)")
    var iso: String?

    @Option(help: "Number of CPU cores (default: 2)")
    var cpu: Int = 2

    @Option(help: "Memory in GB (default: 4, min: 4)")
    var mem: Int = 4

    @Option(help: "Disk size in GB (default: 64)")
    var disk: Int = 64

    @Option(help: "Network mode: nat or bridged:<interface> (default: nat)")
    var network: String = "nat"

    @Flag(help: "Run in headless mode (serial console only)")
    var headless: Bool = false

    func run() async throws {
        // Parse VM type
        guard let vmType = VMType(rawValue: type.lowercased()) else {
            throw DarwinVMError.invalidArgument("Type must be 'macos' or 'linux'")
        }

        // Validate type-specific requirements
        if vmType == .macOS && ipsw == nil {
            throw DarwinVMError.invalidArgument("macOS VMs require --ipsw <path>")
        }

        // Check name uniqueness
        guard !VMStore.exists(name: name) else {
            throw DarwinVMError.vmAlreadyExists(name)
        }

        // Validate resources
        try Validator.validateAll(cpu: cpu, memGB: mem, diskGB: disk)

        // Parse network mode
        let networkMode = try NetworkMode.parse(network)

        // Create VM directory
        let dir = VMDirectory(name: name)
        try dir.create()

        do {
            // Create config
            var config = VMConfig(
                name: name,
                type: vmType,
                cpuCount: cpu,
                memoryGB: mem,
                diskSizeGB: disk,
                network: networkMode,
                headless: headless,
                ipswPath: ipsw,
                isoPath: iso
            )

            // Create disk image
            print("Creating \(disk) GB disk image...")
            try DiskManager.createSparseImage(at: dir.diskURL, sizeBytes: config.diskSize)

            switch vmType {
            case .macOS:
                try await createMacOS(config: &config, dir: dir)
            case .linux:
                try createLinux(config: config, dir: dir)
            }

            // Save config
            try VMStore.saveConfig(config)
            print("VM '\(name)' created successfully.")
        } catch {
            // Cleanup on failure
            try? dir.remove()
            throw error
        }
    }

    @MainActor
    private func createMacOS(config: inout VMConfig, dir: VMDirectory) async throws {
        guard let ipswPath = ipsw else { return }

        let ipswURL = URL(fileURLWithPath: ipswPath)
        print("Loading IPSW restore image...")
        let restoreImage = try await VZMacOSRestoreImage.image(from: ipswURL)

        guard let requirements = restoreImage.mostFeaturefulSupportedConfiguration else {
            throw DarwinVMError.configurationFailed("This IPSW is not supported on this host")
        }

        guard requirements.hardwareModel.isSupported else {
            throw DarwinVMError.configurationFailed("Hardware model is not supported on this host")
        }

        // Ensure CPU/memory meet minimum requirements
        config.cpuCount = max(config.cpuCount, requirements.minimumSupportedCPUCount)
        config.memoryGB = max(config.memoryGB, Int(requirements.minimumSupportedMemorySize / (1024 * 1024 * 1024)))

        // Create machine identifier
        let machineIdentifier = VZMacMachineIdentifier()
        try machineIdentifier.dataRepresentation.write(to: dir.machineIdentifierURL)

        // Save hardware model
        try requirements.hardwareModel.dataRepresentation.write(to: dir.hardwareModelURL)

        // Build configuration and install
        let vzConfig = try MacOSConfigurator.configure(
            config: config,
            dir: dir,
            hardwareModel: requirements.hardwareModel,
            machineIdentifier: machineIdentifier
        )

        let vm = VZVirtualMachine(configuration: vzConfig)
        let installer = VZMacOSInstaller(virtualMachine: vm, restoringFromImageAt: ipswURL)

        print("Installing macOS (this may take 15-30 minutes)...")
        let observation = installer.progress.observe(\.fractionCompleted) { progress, _ in
            let percent = Int(progress.fractionCompleted * 100)
            print("\rInstallation progress: \(percent)%", terminator: "")
            fflush(stdout)
        }

        try await installer.install()
        observation.invalidate()
        print("\nmacOS installation complete.")
    }

    private func createLinux(config: VMConfig, dir: VMDirectory) throws {
        // Create EFI variable store
        _ = try VZEFIVariableStore(creatingVariableStoreAt: dir.nvramURL)

        // Create machine identifier
        let machineIdentifier = VZGenericMachineIdentifier()
        try machineIdentifier.dataRepresentation.write(to: dir.machineIdentifierURL)

        if let isoPath = config.isoPath {
            print("ISO '\(isoPath)' will be attached on first boot.")
        }
    }
}
