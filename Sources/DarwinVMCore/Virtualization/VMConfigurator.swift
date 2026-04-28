import Foundation
import Virtualization

/// Orchestrator: VMConfig -> VZVirtualMachineConfiguration
public struct VMConfigurator: Sendable {
    @MainActor
    public static func configureForStart(
        config: VMConfig,
        dir: VMDirectory,
        attachISO: Bool = false
    ) throws -> VZVirtualMachineConfiguration {
        switch config.type {
        case .macOS:
            return try MacOSConfigurator.configureForBoot(config: config, dir: dir)
        case .linux:
            return try LinuxConfigurator.configure(config: config, dir: dir, attachISO: attachISO)
        }
    }
}
