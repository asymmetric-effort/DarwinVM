import Foundation
import Virtualization

public struct DeviceConfigurator: Sendable {
    @MainActor
    public static func createDiskAttachment(url: URL, readOnly: Bool = false) throws -> VZVirtioBlockDeviceConfiguration {
        let attachment = try VZDiskImageStorageDeviceAttachment(url: url, readOnly: readOnly)
        return VZVirtioBlockDeviceConfiguration(attachment: attachment)
    }

    @MainActor
    public static func createISOAttachment(url: URL) throws -> VZVirtioBlockDeviceConfiguration {
        let attachment = try VZDiskImageStorageDeviceAttachment(url: url, readOnly: true)
        return VZVirtioBlockDeviceConfiguration(attachment: attachment)
    }

    @MainActor
    public static func createSerialPort() -> VZVirtioConsoleDeviceSerialPortConfiguration {
        let serial = VZVirtioConsoleDeviceSerialPortConfiguration()
        let input = VZFileHandleSerialPortAttachment(
            fileHandleForReading: FileHandle.standardInput,
            fileHandleForWriting: FileHandle.standardOutput)
        serial.attachment = input
        return serial
    }

    @MainActor
    public static func createEntropyDevice() -> VZVirtioEntropyDeviceConfiguration {
        VZVirtioEntropyDeviceConfiguration()
    }

    @MainActor
    public static func createMemoryBalloon() -> VZVirtioTraditionalMemoryBalloonDeviceConfiguration {
        VZVirtioTraditionalMemoryBalloonDeviceConfiguration()
    }

    @MainActor
    public static func createAudioDevices() -> [VZAudioDeviceConfiguration] {
        let audio = VZVirtioSoundDeviceConfiguration()
        let outputStream = VZVirtioSoundDeviceOutputStreamConfiguration()
        outputStream.sink = VZHostAudioOutputStreamSink()
        let inputStream = VZVirtioSoundDeviceInputStreamConfiguration()
        inputStream.source = VZHostAudioInputStreamSource()
        audio.streams = [outputStream, inputStream]
        return [audio]
    }
}
