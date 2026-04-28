import Foundation
import Virtualization

#if canImport(AppKit)
import AppKit

@MainActor
public final class GUIRunner {
    private let vm: VZVirtualMachine
    private let vmName: String

    public init(vm: VZVirtualMachine, vmName: String) {
        self.vm = vm
        self.vmName = vmName
    }

    public func run() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1024, height: 768),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "DarwinVM — \(vmName)"
        window.center()

        let vmView = VZVirtualMachineView()
        vmView.virtualMachine = vm
        vmView.capturesSystemKeys = true
        window.contentView = vmView
        window.makeKeyAndOrderFront(nil)

        let delegate = GUIAppDelegate()
        app.delegate = delegate

        app.activate(ignoringOtherApps: true)
        app.run()
    }
}

@MainActor
private final class GUIAppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
#endif
