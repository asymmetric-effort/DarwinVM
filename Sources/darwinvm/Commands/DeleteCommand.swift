import ArgumentParser
import Foundation
import DarwinVMCore

struct DeleteCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a virtual machine"
    )

    @Argument(help: "Name of the virtual machine")
    var name: String

    @Flag(help: "Skip confirmation and force stop if running")
    var force: Bool = false

    func run() async throws {
        // Verify VM exists
        _ = try VMStore.loadConfig(name: name)

        let dir = VMDirectory(name: name)
        let pidFile = PIDFile(url: dir.pidFileURL)

        // Check if running
        if pidFile.isProcessRunning {
            if force {
                if let pid = pidFile.read() {
                    print("Force stopping VM '\(name)'...")
                    kill(pid, SIGKILL)
                    // Wait for process to exit
                    for _ in 0..<20 {
                        if kill(pid, 0) != 0 { break }
                        try await Task.sleep(nanoseconds: 100_000_000)
                    }
                }
            } else {
                throw DarwinVMError.vmAlreadyRunning(
                    "\(name)'. Stop it first or use --force")
            }
        }

        // Confirmation prompt (skip if --force)
        if !force {
            print("Delete VM '\(name)' and all its data? This cannot be undone. [y/N] ", terminator: "")
            fflush(stdout)
            guard let answer = readLine()?.lowercased(), answer == "y" || answer == "yes" else {
                print("Cancelled.")
                return
            }
        }

        try VMStore.delete(name: name)
        print("VM '\(name)' deleted.")
    }
}
