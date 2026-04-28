import Foundation

public final class SignalHandler: Sendable {
    private let callback: @Sendable () -> Void

    private let sigtermSource: DispatchSourceSignal
    private let sigintSource: DispatchSourceSignal

    public init(callback: @escaping @Sendable () -> Void) {
        self.callback = callback

        // Ignore default signal handling
        signal(SIGTERM, SIG_IGN)
        signal(SIGINT, SIG_IGN)

        self.sigtermSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        self.sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)

        sigtermSource.setEventHandler { callback() }
        sigintSource.setEventHandler { callback() }

        sigtermSource.resume()
        sigintSource.resume()
    }

    deinit {
        sigtermSource.cancel()
        sigintSource.cancel()
    }
}
