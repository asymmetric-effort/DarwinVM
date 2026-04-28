import Foundation

public enum DarwinVMError: LocalizedError, Sendable {
    case vmAlreadyExists(String)
    case vmNotFound(String)
    case vmAlreadyRunning(String)
    case vmNotRunning(String)
    case invalidArgument(String)
    case validationFailed(String)
    case diskCreationFailed(String)
    case configurationFailed(String)
    case installationFailed(String)
    case startFailed(String)
    case stopFailed(String)
    case fileOperationFailed(String)
    case unsupported(String)

    public var errorDescription: String? {
        switch self {
        case .vmAlreadyExists(let name):
            return "VM '\(name)' already exists"
        case .vmNotFound(let name):
            return "VM '\(name)' not found"
        case .vmAlreadyRunning(let name):
            return "VM '\(name)' is already running"
        case .vmNotRunning(let name):
            return "VM '\(name)' is not running"
        case .invalidArgument(let msg):
            return "Invalid argument: \(msg)"
        case .validationFailed(let msg):
            return "Validation failed: \(msg)"
        case .diskCreationFailed(let msg):
            return "Disk creation failed: \(msg)"
        case .configurationFailed(let msg):
            return "Configuration failed: \(msg)"
        case .installationFailed(let msg):
            return "Installation failed: \(msg)"
        case .startFailed(let msg):
            return "Start failed: \(msg)"
        case .stopFailed(let msg):
            return "Stop failed: \(msg)"
        case .fileOperationFailed(let msg):
            return "File operation failed: \(msg)"
        case .unsupported(let msg):
            return "Unsupported: \(msg)"
        }
    }
}
