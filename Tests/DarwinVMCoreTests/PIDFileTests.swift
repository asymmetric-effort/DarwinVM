import Testing
import Foundation
@testable import DarwinVMCore

@Suite("PIDFile Tests")
struct PIDFileTests {
    private func makeTempPIDFile() -> (PIDFile, URL) {
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("darwinvm_pid_test_\(UUID().uuidString).pid")
        return (PIDFile(url: tmpURL), tmpURL)
    }

    @Test("write() writes current PID to file")
    func writeCurrentPID() throws {
        let (pidFile, tmpURL) = makeTempPIDFile()
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        try pidFile.write()
        let contents = try String(contentsOf: tmpURL, encoding: .utf8)
        let expected = ProcessInfo.processInfo.processIdentifier
        #expect(Int32(contents.trimmingCharacters(in: .whitespacesAndNewlines)) == expected)
    }

    @Test("read() returns the written PID")
    func readWrittenPID() throws {
        let (pidFile, tmpURL) = makeTempPIDFile()
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        try pidFile.write()
        let pid = pidFile.read()
        #expect(pid == ProcessInfo.processInfo.processIdentifier)
    }

    @Test("read() returns nil for missing file")
    func readMissingFile() {
        let (pidFile, _) = makeTempPIDFile()
        #expect(pidFile.read() == nil)
    }

    @Test("read() returns nil for non-numeric content")
    func readNonNumeric() throws {
        let (pidFile, tmpURL) = makeTempPIDFile()
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        try Data("not-a-number".utf8).write(to: tmpURL, options: .atomic)
        #expect(pidFile.read() == nil)
    }

    @Test("remove() deletes the file")
    func removeDeletesFile() throws {
        let (pidFile, tmpURL) = makeTempPIDFile()
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        try pidFile.write()
        #expect(FileManager.default.fileExists(atPath: tmpURL.path))
        pidFile.remove()
        #expect(!FileManager.default.fileExists(atPath: tmpURL.path))
    }

    @Test("remove() doesn't throw for missing file")
    func removeNoThrowForMissing() {
        let (pidFile, _) = makeTempPIDFile()
        pidFile.remove() // should not throw
    }

    @Test("isProcessRunning returns true for current process")
    func isProcessRunningTrue() throws {
        let (pidFile, tmpURL) = makeTempPIDFile()
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        try pidFile.write()
        #expect(pidFile.isProcessRunning == true)
    }

    @Test("isProcessRunning returns false for dead PID")
    func isProcessRunningFalse() throws {
        let (pidFile, tmpURL) = makeTempPIDFile()
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        try Data("99999".utf8).write(to: tmpURL, options: .atomic)
        #expect(pidFile.isProcessRunning == false)
    }

    @Test("isProcessRunning returns false when no PID file")
    func isProcessRunningNoFile() {
        let (pidFile, _) = makeTempPIDFile()
        #expect(pidFile.isProcessRunning == false)
    }
}
