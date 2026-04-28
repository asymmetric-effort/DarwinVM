import Foundation
import Virtualization

public struct NetworkConfigurator: Sendable {
    @MainActor
    public static func createNetworkDevices(for mode: NetworkMode) -> [VZNetworkDeviceConfiguration] {
        let attachment: VZNetworkDeviceAttachment
        switch mode {
        case .nat:
            attachment = VZNATNetworkDeviceAttachment()
        case .bridged(let interfaceId):
            if let iface = VZBridgedNetworkInterface.networkInterfaces.first(where: { $0.identifier == interfaceId }) {
                attachment = VZBridgedNetworkDeviceAttachment(interface: iface)
            } else {
                // Fallback to NAT if interface not found
                print("Warning: Bridge interface '\(interfaceId)' not found, falling back to NAT")
                attachment = VZNATNetworkDeviceAttachment()
            }
        }
        let config = VZVirtioNetworkDeviceConfiguration()
        config.attachment = attachment
        return [config]
    }
}
