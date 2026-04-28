import Foundation

/// Creates sparse RAW disk images using ftruncate (APFS-efficient).
public struct DiskManager: Sendable {
    public static func createSparseImage(at url: URL, sizeBytes: UInt64) throws {
        FileManager.default.createFile(atPath: url.path, contents: nil)

        let fd = open(url.path, O_WRONLY)
        guard fd >= 0 else {
            throw DarwinVMError.diskCreationFailed("Cannot open \(url.path): \(String(cString: strerror(errno)))")
        }
        defer { close(fd) }

        let result = ftruncate(fd, off_t(sizeBytes))
        guard result == 0 else {
            throw DarwinVMError.diskCreationFailed("ftruncate failed: \(String(cString: strerror(errno)))")
        }
    }
}
