import Foundation
import Virtualization

@MainActor
public final class VMRunner {
    public let config: VMConfig
    public let dir: VMDirectory
    private var vm: VZVirtualMachine?
    private var delegate: VMDelegate?
    private var pidFile: PIDFile
    private var signalHandler: SignalHandler?

    public init(config: VMConfig, dir: VMDirectory) {
        self.config = config
        self.dir = dir
        self.pidFile = PIDFile(url: dir.pidFileURL)
    }

    public func start(attachISO: Bool = false) async throws {
        // Check not already running
        if pidFile.isProcessRunning {
            throw DarwinVMError.vmAlreadyRunning(config.name)
        }

        // Build VZ configuration
        let vzConfig = try VMConfigurator.configureForStart(
            config: config, dir: dir, attachISO: attachISO)

        let virtualMachine = VZVirtualMachine(configuration: vzConfig)

        // Set up delegate
        let vmDelegate = VMDelegate(
            onStop: { [weak self] in
                self?.cleanup()
                print("VM '\(self?.config.name ?? "")' stopped.")
                Darwin.exit(0)
            },
            onError: { [weak self] error in
                self?.cleanup()
                print("VM '\(self?.config.name ?? "")' stopped with error: \(error.localizedDescription)")
                Darwin.exit(1)
            }
        )
        virtualMachine.delegate = vmDelegate
        self.delegate = vmDelegate
        self.vm = virtualMachine

        // Write PID file
        try pidFile.write()

        // Save state
        let state = VMState(pid: ProcessInfo.processInfo.processIdentifier)
        try VMStore.saveState(state, name: config.name)

        // Install signal handler for graceful shutdown
        signalHandler = SignalHandler { [weak self] in
            Task { @MainActor in
                await self?.requestStop()
            }
        }

        // Start the VM
        try await virtualMachine.start()
        print("VM '\(config.name)' started (PID: \(ProcessInfo.processInfo.processIdentifier))")
    }

    public func requestStop() async {
        guard let vm = self.vm else { return }
        do {
            try vm.requestStop()
        } catch {
            print("Graceful stop failed, forcing: \(error.localizedDescription)")
            try? await vm.stop()
            cleanup()
            Darwin.exit(1)
        }
    }

    public func forceStop() async {
        guard let vm = self.vm else { return }
        do {
            try await vm.stop()
        } catch {
            print("Force stop failed: \(error.localizedDescription)")
        }
        cleanup()
    }

    public func installMacOS(ipswURL: URL) async throws {
        guard let vm = self.vm else {
            throw DarwinVMError.installationFailed("VM not initialized")
        }
        let installer = VZMacOSInstaller(virtualMachine: vm, restoringFromImageAt: ipswURL)

        print("Installing macOS from \(ipswURL.lastPathComponent)...")

        let observation = installer.progress.observe(\.fractionCompleted) { progress, _ in
            let percent = Int(progress.fractionCompleted * 100)
            print("\rInstallation progress: \(percent)%", terminator: "")
            fflush(stdout)
        }

        try await installer.install()
        observation.invalidate()
        print("\nInstallation complete.")
    }

    private func cleanup() {
        pidFile.remove()
        VMStore.removeState(name: config.name)
    }
}
