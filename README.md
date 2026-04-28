# DarwinVM

A CLI/GUI tool for managing virtual machines on Apple Silicon Macs using Apple's [Virtualization.framework](https://developer.apple.com/documentation/virtualization).

## Features

- **macOS and Linux guests** — Create macOS VMs from IPSW restore images or Linux VMs from ISO installers
- **Full lifecycle management** — Create, start, stop, list, and delete VMs
- **GUI and headless modes** — Display VM output in a native window or use serial console via stdin/stdout
- **NAT and bridged networking** — NAT by default, or bridge to a host interface
- **Resource validation** — CPU, memory, and disk constraints enforced against host capabilities
- **Sparse disk images** — APFS-efficient RAW images that only consume space as data is written
- **Cross-process control** — Stop a running VM from any terminal via PID-based signaling
- **Swift 6 concurrency** — Full Sendable compliance with `@MainActor` isolation for Virtualization.framework

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon (M1 or later)
- Xcode Command Line Tools or Xcode (for building)
- Code signing with virtualization entitlements (handled by `make sign`)

## Quick Start

```bash
# Build and install
make release && make sign
sudo make install

# Create a Linux VM
darwinvm create ubuntu --type linux --iso ~/Downloads/ubuntu-24.04-live-server-arm64.iso \
    --cpu 4 --mem 8 --disk 32

# Start the VM (GUI window)
darwinvm start ubuntu

# Start headless (serial console)
darwinvm start ubuntu --headless

# Stop the VM (from another terminal)
darwinvm stop ubuntu

# List all VMs
darwinvm list

# Delete a VM
darwinvm delete ubuntu
```

## Building

```bash
# Debug build
make build

# Release build (optimized)
make release

# Codesign with entitlements (required for VM operations)
make sign

# Install to /usr/local/bin
sudo make install

# Run tests
make test

# Clean build artifacts
make clean
```

You can also build directly with Swift Package Manager:

```bash
swift build
swift build -c release
swift test
```

> **Note:** The binary must be codesigned with the entitlements in `darwinvm.entitlements` before it can create or run VMs. Use `make sign` after building.

## CLI Reference

See [docs/cli.md](docs/cli.md) for the complete CLI reference.

```
darwinvm <subcommand>

SUBCOMMANDS:
  create    Create a new virtual machine
  start     Start a virtual machine
  stop      Stop a running virtual machine
  list      List all virtual machines
  delete    Delete a virtual machine
```

## Documentation

| Document | Description |
|---|---|
| [CLI Reference](docs/cli.md) | Complete command-line interface documentation |
| [Architecture](docs/architecture.md) | Project structure, module design, and data flow |
| [macOS VMs](docs/macos-vms.md) | Creating and managing macOS guest VMs |
| [Linux VMs](docs/linux-vms.md) | Creating and managing Linux guest VMs |
| [Networking](docs/networking.md) | NAT and bridged networking configuration |
| [Configuration](docs/configuration.md) | VM configuration format and storage layout |
| [Building](docs/building.md) | Build system, entitlements, and code signing |
| [Troubleshooting](docs/troubleshooting.md) | Common issues and solutions |

## How It Works

DarwinVM wraps Apple's Virtualization.framework in a convenient CLI. Each VM is stored as a directory under `~/.darwinvm/vms/<name>/` containing its configuration, disk image, and platform-specific files.

- **macOS VMs** use `VZMacOSBootLoader`, `VZMacPlatformConfiguration`, and install from IPSW restore images via `VZMacOSInstaller`
- **Linux VMs** use `VZEFIBootLoader`, `VZGenericPlatformConfiguration`, and boot from ISO images attached as block devices

VMs run as foreground processes. In GUI mode, a native `NSWindow` hosts a `VZVirtualMachineView`. In headless mode, the serial console is wired to stdin/stdout. Cross-process stop works by sending SIGTERM to the PID recorded in the VM's lockfile.

## License

See [LICENSE](LICENSE) for details.
