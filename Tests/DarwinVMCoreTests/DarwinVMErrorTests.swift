import Testing
import Foundation
@testable import DarwinVMCore

@Suite("DarwinVMError Tests")
struct DarwinVMErrorTests {
    @Test("vmAlreadyExists produces correct description")
    func vmAlreadyExists() {
        let error = DarwinVMError.vmAlreadyExists("my-vm")
        #expect(error.errorDescription?.contains("my-vm") == true)
        #expect(error.errorDescription?.contains("already exists") == true)
    }

    @Test("vmNotFound produces correct description")
    func vmNotFound() {
        let error = DarwinVMError.vmNotFound("missing-vm")
        #expect(error.errorDescription?.contains("missing-vm") == true)
        #expect(error.errorDescription?.contains("not found") == true)
    }

    @Test("vmAlreadyRunning produces correct description")
    func vmAlreadyRunning() {
        let error = DarwinVMError.vmAlreadyRunning("running-vm")
        #expect(error.errorDescription?.contains("running-vm") == true)
        #expect(error.errorDescription?.contains("already running") == true)
    }

    @Test("vmNotRunning produces correct description")
    func vmNotRunning() {
        let error = DarwinVMError.vmNotRunning("stopped-vm")
        #expect(error.errorDescription?.contains("stopped-vm") == true)
        #expect(error.errorDescription?.contains("not running") == true)
    }

    @Test("invalidArgument produces correct description")
    func invalidArgument() {
        let error = DarwinVMError.invalidArgument("bad value")
        #expect(error.errorDescription?.contains("bad value") == true)
        #expect(error.errorDescription?.contains("Invalid argument") == true)
    }

    @Test("validationFailed produces correct description")
    func validationFailed() {
        let error = DarwinVMError.validationFailed("too many CPUs")
        #expect(error.errorDescription?.contains("too many CPUs") == true)
        #expect(error.errorDescription?.contains("Validation failed") == true)
    }

    @Test("diskCreationFailed produces correct description")
    func diskCreationFailed() {
        let error = DarwinVMError.diskCreationFailed("no space")
        #expect(error.errorDescription?.contains("no space") == true)
        #expect(error.errorDescription?.contains("Disk creation failed") == true)
    }

    @Test("configurationFailed produces correct description")
    func configurationFailed() {
        let error = DarwinVMError.configurationFailed("invalid config")
        #expect(error.errorDescription?.contains("invalid config") == true)
        #expect(error.errorDescription?.contains("Configuration failed") == true)
    }

    @Test("installationFailed produces correct description")
    func installationFailed() {
        let error = DarwinVMError.installationFailed("ipsw missing")
        #expect(error.errorDescription?.contains("ipsw missing") == true)
        #expect(error.errorDescription?.contains("Installation failed") == true)
    }

    @Test("startFailed produces correct description")
    func startFailed() {
        let error = DarwinVMError.startFailed("port in use")
        #expect(error.errorDescription?.contains("port in use") == true)
        #expect(error.errorDescription?.contains("Start failed") == true)
    }

    @Test("stopFailed produces correct description")
    func stopFailed() {
        let error = DarwinVMError.stopFailed("timeout")
        #expect(error.errorDescription?.contains("timeout") == true)
        #expect(error.errorDescription?.contains("Stop failed") == true)
    }

    @Test("fileOperationFailed produces correct description")
    func fileOperationFailed() {
        let error = DarwinVMError.fileOperationFailed("permission denied")
        #expect(error.errorDescription?.contains("permission denied") == true)
        #expect(error.errorDescription?.contains("File operation failed") == true)
    }

    @Test("unsupported produces correct description")
    func unsupported() {
        let error = DarwinVMError.unsupported("not available")
        #expect(error.errorDescription?.contains("not available") == true)
        #expect(error.errorDescription?.contains("Unsupported") == true)
    }
}
