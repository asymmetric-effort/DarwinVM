import Foundation

/// Runs the VM in headless mode using RunLoop (serial console on stdin/stdout).
public struct HeadlessRunner: Sendable {
    public static func run() {
        // Keep the process alive via the main RunLoop.
        // Serial console is already wired via DeviceConfigurator.createSerialPort().
        RunLoop.main.run()
    }
}
