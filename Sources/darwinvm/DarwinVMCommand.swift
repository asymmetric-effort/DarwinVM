import ArgumentParser

@main
struct DarwinVMCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "darwinvm",
        abstract: "Manage virtual machines on Apple Silicon using Virtualization.framework",
        subcommands: [
            CreateCommand.self,
            StartCommand.self,
            StopCommand.self,
            ListCommand.self,
            DeleteCommand.self,
        ]
    )
}
