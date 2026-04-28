import Testing
import Foundation
@testable import DarwinVMCore
@testable import darwinvm

@Suite("TableFormatter Tests")
struct TableFormatterTests {
    @Test("Empty configs returns 'No virtual machines found.'")
    func emptyConfigs() {
        let result = TableFormatter.format(configs: [])
        #expect(result == "No virtual machines found.")
    }

    @Test("Single NAT Linux VM formats correctly")
    func singleNATLinux() {
        let config = VMConfig(
            name: "my-linux",
            type: .linux,
            cpuCount: 4,
            memoryGB: 8,
            diskSizeGB: 64,
            network: .nat,
            headless: true
        )
        let result = TableFormatter.format(configs: [config])
        let lines = result.split(separator: "\n", omittingEmptySubsequences: false)

        #expect(lines.count == 2) // header + 1 row
        #expect(lines[0].contains("NAME"))
        #expect(lines[1].contains("my-linux"))
        #expect(lines[1].contains("linux"))
        #expect(lines[1].contains("4"))
        #expect(lines[1].contains("8GB"))
        #expect(lines[1].contains("64GB"))
        #expect(lines[1].contains("nat"))
        #expect(lines[1].contains("stopped"))
    }

    @Test("Single bridged macOS VM formats correctly")
    func singleBridgedMacOS() {
        let config = VMConfig(
            name: "macos-dev",
            type: .macOS,
            cpuCount: 2,
            memoryGB: 4,
            diskSizeGB: 32,
            network: .bridged(interfaceId: "en0"),
            headless: false
        )
        let result = TableFormatter.format(configs: [config])
        let lines = result.split(separator: "\n", omittingEmptySubsequences: false)

        #expect(lines.count == 2)
        #expect(lines[1].contains("macos-dev"))
        #expect(lines[1].contains("macos"))
        #expect(lines[1].contains("bridged:en0"))
    }

    @Test("Multiple VMs sorted and formatted")
    func multipleVMs() {
        let configs = [
            VMConfig(name: "bravo", type: .linux),
            VMConfig(name: "alpha", type: .macOS),
        ]
        let result = TableFormatter.format(configs: configs)
        let lines = result.split(separator: "\n", omittingEmptySubsequences: false)

        #expect(lines.count == 3) // header + 2 rows
        // Note: TableFormatter doesn't sort — it formats in the order given
        #expect(lines[1].contains("bravo"))
        #expect(lines[2].contains("alpha"))
    }

    @Test("Header row contains all column names")
    func headerContainsColumns() {
        let config = VMConfig(name: "test", type: .linux)
        let result = TableFormatter.format(configs: [config])
        let header = String(result.split(separator: "\n")[0])

        #expect(header.contains("NAME"))
        #expect(header.contains("TYPE"))
        #expect(header.contains("CPU"))
        #expect(header.contains("MEM"))
        #expect(header.contains("DISK"))
        #expect(header.contains("STATUS"))
        #expect(header.contains("NETWORK"))
    }
}
