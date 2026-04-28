import Foundation
import Virtualization

@MainActor
public final class VMDelegate: NSObject, VZVirtualMachineDelegate {
    private let onStop: @MainActor () -> Void
    private let onError: @MainActor (Error) -> Void

    public init(
        onStop: @escaping @MainActor () -> Void,
        onError: @escaping @MainActor (Error) -> Void
    ) {
        self.onStop = onStop
        self.onError = onError
    }

    public nonisolated func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        Task { @MainActor in
            self.onStop()
        }
    }

    public nonisolated func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) {
        Task { @MainActor in
            self.onError(error)
        }
    }
}
