# Networking

## Overview

DarwinVM supports two networking modes:

| Mode | Flag | Description |
|---|---|---|
| NAT | `--network nat` | Default. VM gets a private IP; outbound traffic is NATed through the host |
| Bridged | `--network bridged:<iface>` | VM appears as a device on the host's physical network |

## NAT Networking (Default)

NAT is the default and simplest networking mode. No additional configuration is required.

```bash
darwinvm create my-vm --type linux --iso ubuntu.iso --network nat
```

### How It Works

- Uses `VZNATNetworkDeviceAttachment` from Virtualization.framework
- The VM gets a private IP address (typically in the `192.168.64.0/24` range)
- Outbound traffic is NATed through the host's network connection
- DNS resolution works via the host
- The host can reach the VM at its private IP
- Devices on the external network cannot reach the VM directly

### Use Cases

- Development and testing
- Internet access from the guest
- SSH from host to guest
- When network isolation is desired

## Bridged Networking

Bridged mode places the VM directly on the host's physical network. The VM gets its own IP from the network's DHCP server and is visible to other devices.

```bash
darwinvm create my-vm --type linux --iso ubuntu.iso --network bridged:en0
```

### Requirements

- The `com.apple.vm.networking` entitlement (included in `darwinvm.entitlements`)
- A valid network interface identifier (e.g., `en0` for Wi-Fi, `en1` for Ethernet)
- The binary must be codesigned with the entitlements (`make sign`)

### Finding Interface Names

List available network interfaces:

```bash
# Show all interfaces
networksetup -listallhardwareports

# Or use ifconfig
ifconfig -l
```

Common interface names on Apple Silicon Macs:

| Interface | Typical Device |
|---|---|
| `en0` | Wi-Fi |
| `en1` | Thunderbolt Ethernet (or second port) |
| `en2`–`en4` | Additional Ethernet adapters |
| `bridge0` | Thunderbolt Bridge |

### How It Works

- Uses `VZBridgedNetworkDeviceAttachment` with the specified `VZBridgedNetworkInterface`
- The VM appears as a separate device on the physical network
- The VM gets its own IP address from the network's DHCP server
- Other devices on the network can reach the VM directly
- The VM can reach other devices on the network directly

### Fallback Behavior

If the specified bridge interface is not found at VM start time, DarwinVM falls back to NAT with a warning:

```
Warning: Bridge interface 'en5' not found, falling back to NAT
```

### Use Cases

- Running servers that need to be accessible from other machines
- Network testing where the VM needs a real network presence
- When the VM needs to be on the same subnet as other devices

## Network Device

Both modes use a `VZVirtioNetworkDeviceConfiguration`, which presents as a standard Virtio network device to the guest. Most modern Linux distributions and macOS detect this automatically.

### Guest Configuration

**Linux:** The Virtio network driver (`virtio_net`) is included in most kernels. The device typically appears as `enp0s1` or `eth0`. DHCP should configure it automatically.

**macOS:** Network configuration happens through System Preferences/Settings. The Virtio network adapter is detected automatically.

## Checking Connectivity

From the guest:
```bash
# Check IP address
ip addr show       # Linux
ifconfig           # macOS

# Test connectivity
ping -c 3 8.8.8.8
ping -c 3 google.com
```

From the host (to reach the guest):
```bash
# Find the guest's IP (check serial console or guest OS)
ping <guest-ip>
ssh user@<guest-ip>
```

## Limitations

- Port forwarding for NAT is not currently supported (use bridged mode for inbound access)
- Only one network interface per VM
- Bridged mode on Wi-Fi may have limitations depending on the access point configuration
- No host-only networking mode (use NAT and connect via the private IP)
