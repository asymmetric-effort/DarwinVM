import ArgumentParser
import Foundation
import DarwinVMCore
import Virtualization

struct StartCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "start",
        abstract: "Start a virtual machine"
    )

    @Argument(help: "Name of the virtual machine")
    var name: String

    @Flag(help: "Run in headless mode (serial console only)")
    var headless: Bool = false

    func run() async throws {
        let config = try VMStore.loadConfig(name: name)
        let dir = VMDirectory(name: name)

        // Check not already running
        let pidFile = PIDFile(url: dir.pidFileURL)
        if pidFile.isProcessRunning {
            throw DarwinVMError.vmAlreadyRunning(name)
        }

        // Determine if ISO should be attached (Linux first boot)
        let attachISO = config.type == .linux && config.isoPath != nil
        let useHeadless = headless || config.headless
        let vmName = name

        try await MainActor.run {
            let runner = VMRunner(config: config, dir: dir)

            Task {
                do {
                    try await runner.start(attachISO: attachISO)
                } catch {
                    print("Error starting VM: \(error.localizedDescription)")
                    Darwin.exit(1)
                }

                if useHeadless {
                    // Headless: RunLoop keeps process alive, serial on stdin/stdout
                    return
                }

                #if canImport(AppKit)
                // GUI mode: show window with VZVirtualMachineView
                // The VM is already running inside runner; we need the VZVirtualMachine
                // to attach the view. Re-use by accessing it from the runner.
                #endif
            }

            // Run the main RunLoop to keep everything alive
            // In GUI mode, NSApplication.run() replaces this.
            if useHeadless {
                RunLoop.main.run()
            } else {
                #if canImport(AppKit)
                let vzConfig = try VMConfigurator.configureForStart(
                    config: config, dir: dir, attachISO: attachISO)
                let vm = VZVirtualMachine(configuration: vzConfig)
                let gui = GUIRunner(vm: vm, vmName: vmName)
                gui.run()
                #else
                RunLoop.main.run()
                #endif
            }
        }
    }
}
