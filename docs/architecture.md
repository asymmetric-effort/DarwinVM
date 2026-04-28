# Architecture

## Overview

DarwinVM is structured as two Swift packages:

- **DarwinVMCore** — Library containing all VM management logic, independent of the CLI
- **darwinvm** — Executable CLI that wraps DarwinVMCore with swift-argument-parser commands

This separation allows the core logic to be reused in other contexts (e.g., a SwiftUI app) without depending on the CLI framework.

## Module Layout

```
Sources/
├── DarwinVMCore/           # Library target
│   ├── Models/             # Data types (Codable, Sendable value types)
│   ├── Errors/             # Unified error enum
│   ├── Host/               # Host system queries and validation
│   ├── Storage/            # Filesystem operations (VM directories, disk images)
│   ├── Virtualization/     # Virtualization.framework configuration builders
│   ├── Runtime/            # VM process lifecycle (start, stop, signals)
│   └── Display/            # GUI window and headless console modes
└── darwinvm/               # Executable target
    ├── Commands/           # CLI command definitions
    └── Formatters/         # Output formatting (table)
```

## Layer Diagram

```
┌─────────────────────────────────────────────────┐
│                   darwinvm CLI                   │
│         (AsyncParsableCommand subcommands)       │
├─────────────────────────────────────────────────┤
│                  DarwinVMCore                    │
│  ┌───────────┐ ┌───────────┐ ┌───────────────┐  │
│  │  Display   │ │  Runtime  │ │ Virtualization │  │
│  │ GUIRunner  │ │ VMRunner  │ │ Configurators  │  │
│  │ Headless   │ │ PIDFile   │ │ macOS/Linux    │  │
│  │            │ │ Signals   │ │ Devices/Net    │  │
│  └───────────┘ └───────────┘ └───────────────┘  │
│  ┌───────────┐ ┌───────────┐ ┌───────────────┐  │
│  │  Storage   │ │   Host    │ │    Models      │  │
│  │ VMStore    │ │ HostInfo  │ │ VMConfig       │  │
│  │ VMDir      │ │ Validator │ │ VMType/State   │  │
│  │ DiskMgr    │ │           │ │ NetworkMode    │  │
│  └───────────┘ └───────────┘ └───────────────┘  │
├─────────────────────────────────────────────────┤
│           Apple Virtualization.framework         │
└─────────────────────────────────────────────────┘
```

## Key Design Decisions

### Swift 6 Concurrency

Virtualization.framework requires all VM operations to run on the main actor. The architecture handles this by:

- **`VMRunner`** is `@MainActor` — owns the `VZVirtualMachine` instance
- **`VMDelegate`** is `@MainActor` — receives framework callbacks
- **Model types** (`VMConfig`, `VMState`, `NetworkMode`, `VMType`) are value types, implicitly `Sendable`
- **CLI commands** use `AsyncParsableCommand` and `await MainActor.run { }` to hop to the main actor
- **Signal handlers** use `DispatchSource.makeSignalSource` on `.main` queue to stay on the main thread

### Configurator Pattern

VM configuration is split across multiple configurators to separate concerns:

| Configurator | Responsibility |
|---|---|
| `VMConfigurator` | Orchestrator — dispatches to macOS or Linux configurator |
| `MacOSConfigurator` | macOS platform, boot loader, hardware model, auxiliary storage |
| `LinuxConfigurator` | EFI boot loader, variable store, generic platform, ISO attachment |
| `DeviceConfigurator` | Shared devices: disk, serial, entropy, memory balloon, audio |
| `NetworkConfigurator` | NAT vs bridged network attachment |

### Cross-Process Stop

Since VMs run as foreground processes, stopping from another terminal uses PID-based signaling:

1. The running process writes its PID to `~/.darwinvm/vms/<name>/darwinvm.pid`
2. `darwinvm stop` reads this PID and sends SIGTERM (or SIGKILL with `--force`)
3. The running process has a `SignalHandler` that catches SIGTERM and calls `vm.requestStop()` for graceful guest shutdown
4. On exit, the PID file and state file are cleaned up

### Storage Layout

Each VM gets its own directory under `~/.darwinvm/vms/<name>/`. See [configuration.md](configuration.md) for the full layout.

## Data Flow

### Create Flow

```
CLI (CreateCommand)
 └─ Validator.validateAll()          # Check CPU/mem/disk constraints
 └─ VMDirectory.create()             # Create VM directory
 └─ DiskManager.createSparseImage()  # Create sparse disk file
 └─ [macOS] VZMacOSRestoreImage      # Load IPSW, extract hardware model
 └─ [macOS] MacOSConfigurator        # Build VZ config
 └─ [macOS] VZMacOSInstaller         # Install macOS (15-30 min)
 └─ [Linux] VZEFIVariableStore       # Create NVRAM file
 └─ VMStore.saveConfig()             # Persist config.json
```

### Start Flow

```
CLI (StartCommand)
 └─ VMStore.loadConfig()             # Read config.json
 └─ PIDFile check                    # Ensure not already running
 └─ VMConfigurator.configureForStart()  # Build VZ config
 └─ VMRunner.start()                 # Create VZVirtualMachine, write PID, start
 └─ SignalHandler installed          # SIGTERM/SIGINT handling
 └─ [GUI] GUIRunner.run()            # NSApplication + NSWindow
 └─ [Headless] HeadlessRunner.run()  # RunLoop with serial console
```

### Stop Flow

```
CLI (StopCommand)
 └─ PIDFile.read()                   # Get running process PID
 └─ kill(pid, SIGTERM/SIGKILL)       # Signal the process
 └─ [Running process]
     └─ SignalHandler fires
     └─ VMRunner.requestStop()
     └─ vm.requestStop()             # Graceful guest shutdown
     └─ VMDelegate.guestDidStop()    # Cleanup PID/state files
     └─ exit(0)
```

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| [swift-argument-parser](https://github.com/apple/swift-argument-parser) | 1.5+ | CLI command parsing |
| [swift-testing](https://github.com/apple/swift-testing) | 0.12+ | Unit test framework (test target only) |
| Virtualization.framework | macOS 14+ | Apple's hypervisor framework (system) |
| AppKit | macOS 14+ | GUI window and VM display view (system) |
