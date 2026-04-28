import Foundation
import DarwinVMCore

public struct TableFormatter {
    public struct Column {
        public let header: String
        public let width: Int
    }

    public static func format(configs: [VMConfig]) -> String {
        if configs.isEmpty {
            return "No virtual machines found."
        }

        let columns: [Column] = [
            Column(header: "NAME", width: 20),
            Column(header: "TYPE", width: 8),
            Column(header: "CPU", width: 5),
            Column(header: "MEM", width: 6),
            Column(header: "DISK", width: 6),
            Column(header: "STATUS", width: 10),
            Column(header: "NETWORK", width: 14),
        ]

        var lines: [String] = []

        // Header
        let header = columns.map { $0.header.padding(toLength: $0.width, withPad: " ", startingAt: 0) }
            .joined(separator: "  ")
        lines.append(header)

        // Rows
        for config in configs {
            let pidFile = PIDFile(url: VMDirectory(name: config.name).pidFileURL)
            let status = pidFile.isProcessRunning ? "running" : "stopped"

            let networkStr: String
            switch config.network {
            case .nat: networkStr = "nat"
            case .bridged(let iface): networkStr = "bridged:\(iface)"
            }

            let values: [String] = [
                config.name,
                config.type.rawValue,
                "\(config.cpuCount)",
                "\(config.memoryGB)GB",
                "\(config.diskSizeGB)GB",
                status,
                networkStr,
            ]

            let row = zip(columns, values).map { col, val in
                val.padding(toLength: col.width, withPad: " ", startingAt: 0)
            }.joined(separator: "  ")
            lines.append(row)
        }

        return lines.joined(separator: "\n")
    }
}
