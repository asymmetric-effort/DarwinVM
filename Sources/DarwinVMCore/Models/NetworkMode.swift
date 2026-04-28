import Foundation

public enum NetworkMode: Codable, Sendable, Equatable {
    case nat
    case bridged(interfaceId: String)

    private enum CodingKeys: String, CodingKey {
        case type
        case interfaceId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "nat":
            self = .nat
        case "bridged":
            let iface = try container.decode(String.self, forKey: .interfaceId)
            self = .bridged(interfaceId: iface)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: container,
                debugDescription: "Unknown network mode: \(type)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .nat:
            try container.encode("nat", forKey: .type)
        case .bridged(let iface):
            try container.encode("bridged", forKey: .type)
            try container.encode(iface, forKey: .interfaceId)
        }
    }

    /// Parse from CLI string like "nat" or "bridged:en0"
    public static func parse(_ value: String) throws -> NetworkMode {
        if value == "nat" {
            return .nat
        }
        if value.hasPrefix("bridged:") {
            let iface = String(value.dropFirst("bridged:".count))
            guard !iface.isEmpty else {
                throw DarwinVMError.invalidArgument("bridged network requires interface name (e.g., bridged:en0)")
            }
            return .bridged(interfaceId: iface)
        }
        throw DarwinVMError.invalidArgument("Unknown network mode '\(value)'. Use 'nat' or 'bridged:<interface>'")
    }
}
