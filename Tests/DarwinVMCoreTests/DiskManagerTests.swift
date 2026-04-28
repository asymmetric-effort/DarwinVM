import Testing
import Foundation
@testable import DarwinVMCore

@Suite("DiskManager Tests")
struct DiskManagerTests {
    @Test("Creates sparse file at specified path")
    func createsSparseFile() throws {
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("darwinvm_disk_test_\(UUID().uuidString).img")
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        try DiskManager.createSparseImage(at: tmpURL, sizeBytes: 1024 * 1024 * 1024) // 1 GB
        #expect(FileManager.default.fileExists(atPath: tmpURL.path))
    }

    @Test("File has correct logical size")
    func correctLogicalSize() throws {
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("darwinvm_disk_test_\(UUID().uuidString).img")
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        let sizeBytes: UInt64 = 512 * 1024 * 1024 // 512 MB
        try DiskManager.createSparseImage(at: tmpURL, sizeBytes: sizeBytes)

        let attrs = try FileManager.default.attributesOfItem(atPath: tmpURL.path)
        let fileSize = attrs[.size] as! UInt64
        #expect(fileSize == sizeBytes)
    }

    @Test("File has near-zero actual size (sparse)")
    func sparseFileSize() throws {
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("darwinvm_disk_test_\(UUID().uuidString).img")
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        try DiskManager.createSparseImage(at: tmpURL, sizeBytes: 1024 * 1024 * 1024) // 1 GB logical

        // stat to get actual blocks used
        var statBuf = stat()
        stat(tmpURL.path, &statBuf)
        let actualBytes = UInt64(statBuf.st_blocks) * 512
        // Sparse file should use very little actual disk space (< 1 MB)
        #expect(actualBytes < 1024 * 1024)
    }

    @Test("Throws on invalid path")
    func throwsOnInvalidPath() {
        let badURL = URL(fileURLWithPath: "/nonexistent_parent_\(UUID().uuidString)/disk.img")
        #expect(throws: DarwinVMError.self) {
            try DiskManager.createSparseImage(at: badURL, sizeBytes: 1024)
        }
    }
}
