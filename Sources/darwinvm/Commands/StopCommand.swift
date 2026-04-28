import ArgumentParser
import Foundation
import DarwinVMCore

struct StopCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stop",
        abstract: "Stop a running virtual machine"
    )

    @Argument(help: "Name of the virtual machine")
    var name: String

    @Flag(help: "Force kill the VM process (SIGKILL)")
    var force: Bool = false

    func run() async throws {
        // Verify VM exists
        _ = try VMStore.loadConfig(name: name)

        let dir = VMDirectory(name: name)
        let pidFile = PIDFile(url: dir.pidFileURL)

        guard let pid = pidFile.read(), kill(pid, 0) == 0 else {
            throw DarwinVMError.vmNotRunning(name)
        }

        if force {
            print("Force stopping VM '\(name)' (PID: \(pid))...")
            kill(pid, SIGKILL)
        } else {
            print("Stopping VM '\(name)' (PID: \(pid))...")
            kill(pid, SIGTERM)
        }

        // Wait briefly for process to exit
        for _ in 0..<30 {
            if kill(pid, 0) != 0 { break }
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }

        if kill(pid, 0) == 0 {
            print("VM process still running. Use --force to kill it.")
        } else {
            // Cleanup stale PID file
            pidFile.remove()
            VMStore.removeState(name: name)
            print("VM '\(name)' stopped.")
        }
    }
}
