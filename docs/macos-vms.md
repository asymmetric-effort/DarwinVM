# macOS Virtual Machines

## Overview

DarwinVM can create and run macOS guest VMs on Apple Silicon hosts using IPSW restore images. macOS VMs use the `VZMacPlatformConfiguration` with `VZMacOSBootLoader`, providing near-native performance.

## Prerequisites

- Apple Silicon Mac (M1 or later)
- macOS 14.0 (Sonoma) or later on the host
- An IPSW restore image for the desired macOS version
- Codesigned binary with `com.apple.security.virtualization` entitlement

## Obtaining IPSW Files

IPSW restore images can be downloaded from:

- [Apple Developer Downloads](https://developer.apple.com/download/)
- [ipsw.me](https://ipsw.me/) (community mirror)

The IPSW must be a Universal Mac restore image compatible with Apple Silicon.

## Creating a macOS VM

```bash
darwinvm create my-macos --type macos --ipsw ~/Downloads/UniversalMac_15.0_Restore.ipsw \
    --cpu 4 --mem 8 --disk 64
```

### What Happens During Creation

1. **Validation** — CPU, memory, and disk parameters are checked against host capabilities
2. **IPSW Loading** — The restore image is loaded via `VZMacOSRestoreImage.image(from:)`
3. **Hardware Model Extraction** — `mostFeaturefulSupportedConfiguration` provides the hardware model and minimum requirements
4. **Resource Adjustment** — CPU and memory are bumped up to meet minimum requirements if necessary
5. **Identity Generation** — A unique `VZMacMachineIdentifier` is created and persisted
6. **Auxiliary Storage** — `VZMacAuxiliaryStorage` is created for the macOS boot environment
7. **Disk Image** — A sparse RAW disk image is created via `ftruncate`
8. **macOS Installation** — `VZMacOSInstaller` installs macOS onto the disk image

> **Note:** Installation takes 15–30 minutes depending on the IPSW size and host performance. Progress is displayed as a percentage.

### Files Created

```
~/.darwinvm/vms/my-macos/
├── config.json        # VM configuration
├── disk.img           # Main disk image (sparse)
├── AuxiliaryStorage   # macOS boot environment data
├── HardwareModel      # Persisted VZMacHardwareModel
└── MachineIdentifier  # Persisted VZMacMachineIdentifier
```

## Starting a macOS VM

```bash
# GUI mode (default) — opens a window with the macOS display
darwinvm start my-macos

# Headless mode — serial console on stdin/stdout
darwinvm start my-macos --headless
```

### GUI Mode

In GUI mode, DarwinVM creates a native `NSWindow` containing a `VZVirtualMachineView`. The display runs at 1920x1200 pixels at 144 PPI (Retina).

Features available in GUI mode:
- Full keyboard and mouse input (USB keyboard + screen coordinate pointing device)
- System key capture (e.g., Cmd+Tab is sent to the guest)
- Window resizing

### First Boot

After installation, the first boot will present the macOS Setup Assistant. You'll need to:

1. Select language and region
2. Create a user account
3. Configure system preferences

## Display Configuration

macOS VMs use `VZMacGraphicsDeviceConfiguration` with a default display of:
- 1920 x 1200 pixels
- 144 pixels per inch (Retina)

## Networking

By default, macOS VMs use NAT networking, which provides:
- Outbound internet access
- No inbound access from the host network
- DNS resolution via the host

For bridged networking:
```bash
darwinvm create my-macos --type macos --ipsw restore.ipsw --network bridged:en0
```

See [networking.md](networking.md) for details.

## Audio

macOS VMs include a Virtio sound device with both output (host speakers) and input (host microphone) streams.

## Limitations

- macOS VMs can only run on Apple Silicon Macs (not Intel)
- The guest macOS version must be compatible with the host hardware
- Only one macOS VM can run at a time per host (Virtualization.framework limitation on some configurations)
- GPU acceleration is provided through the paravirtualized `VZMacGraphicsDeviceConfiguration`, not full GPU passthrough
- No shared folders in the current implementation (can be added via `VZVirtioFileSystemDeviceConfiguration`)
