# Linux Virtual Machines

## Overview

DarwinVM can create and run Linux guest VMs using EFI boot with ISO installer images. Linux VMs use `VZGenericPlatformConfiguration` with `VZEFIBootLoader`, supporting any ARM64 Linux distribution.

## Prerequisites

- Apple Silicon Mac (M1 or later)
- macOS 14.0 (Sonoma) or later on the host
- An ARM64 (aarch64) Linux ISO installer image
- Codesigned binary with `com.apple.security.virtualization` entitlement

## Supported Distributions

Any ARM64 Linux distribution that supports EFI boot should work, including:

- Ubuntu Server/Desktop (arm64)
- Debian (arm64)
- Fedora (aarch64)
- Arch Linux ARM
- Alpine Linux (aarch64)
- openSUSE (aarch64)

> **Important:** You must use the ARM64/aarch64 variant of the ISO, not the x86_64/amd64 version.

## Creating a Linux VM

```bash
darwinvm create my-linux --type linux --iso ~/Downloads/ubuntu-24.04-live-server-arm64.iso \
    --cpu 4 --mem 8 --disk 32
```

### What Happens During Creation

1. **Validation** — CPU, memory, and disk parameters are checked against host capabilities
2. **EFI Variable Store** — A `VZEFIVariableStore` (NVRAM) file is created for EFI boot variables
3. **Machine Identifier** — A unique `VZGenericMachineIdentifier` is generated and persisted
4. **Disk Image** — A sparse RAW disk image is created via `ftruncate`
5. **Configuration Saved** — The ISO path is recorded in `config.json` for attachment on first boot

> **Note:** Unlike macOS VMs, Linux VM creation is fast (seconds). The ISO is not used until the first `start`.

### Files Created

```
~/.darwinvm/vms/my-linux/
├── config.json        # VM configuration (includes ISO path)
├── disk.img           # Main disk image (sparse)
├── MachineIdentifier  # Persisted VZGenericMachineIdentifier
└── NVRAM.efivars      # EFI variable store
```

## Starting a Linux VM

```bash
# GUI mode — opens a window with the VM display
darwinvm start my-linux

# Headless mode — serial console on stdin/stdout
darwinvm start my-linux --headless
```

### First Boot (Installation)

On the first start, the ISO is attached as a block device alongside the main disk. The VM boots from the ISO's EFI boot loader, presenting the distribution's installer.

1. Start the VM: `darwinvm start my-linux`
2. Follow the distribution's installation wizard
3. Install the OS to the main disk (typically `/dev/vda`)
4. Reboot when prompted — the VM will restart

### Subsequent Boots

After installation, the VM boots from the installed OS on the disk image via the EFI variable store. The ISO remains configured but the installed bootloader takes priority in the EFI boot order.

> **Tip:** If you want to remove the ISO attachment after installation, you can edit `~/.darwinvm/vms/<name>/config.json` and set `"isoPath"` to `null`.

## Headless Mode and Serial Console

Headless mode is particularly useful for Linux server VMs:

```bash
darwinvm start my-linux --headless
```

In headless mode:
- The serial console is wired to stdin/stdout
- You interact with the VM directly in your terminal
- No GUI window is created

For serial console to work, the Linux guest must have a serial console configured. Most server ISOs configure this automatically. For desktop distributions, you may need to add a kernel parameter:

```
console=ttyAMA0
```

### SSH Access

For headless server VMs, SSH is often more practical than the serial console:

1. Install OpenSSH server in the guest during installation
2. The VM gets a NAT IP address (typically `192.168.64.x`)
3. SSH from the host: `ssh user@<vm-ip>`

To find the VM's IP address, check the serial console output during boot or run `ip addr` in the guest.

## Display Configuration

Linux VMs use `VZVirtioGraphicsDeviceConfiguration` with a default scanout of:
- 1920 x 1080 pixels

The Virtio GPU provides basic graphics. For desktop Linux distributions, you'll get a functional desktop environment, though without GPU acceleration.

## Audio

Linux VMs include a Virtio sound device. The guest needs appropriate drivers (included in most modern Linux kernels as `snd_virtio`).

## Networking

By default, Linux VMs use NAT networking. See [networking.md](networking.md) for configuration options.

## Limitations

- No GPU acceleration (Virtio GPU provides software rendering only)
- No shared folders in the current implementation
- Serial console requires guest-side configuration for some distributions
- EFI boot only (no legacy BIOS boot support)
