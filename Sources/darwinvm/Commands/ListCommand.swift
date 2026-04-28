import ArgumentParser
import Foundation
import DarwinVMCore

struct ListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all virtual machines"
    )

    func run() async throws {
        let configs = try VMStore.listAll()
        print(TableFormatter.format(configs: configs))
    }
}
