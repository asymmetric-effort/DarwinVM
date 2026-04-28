# Configuration and Storage

## Storage Location

All VM data is stored under `~/.darwinvm/vms/`. Each VM gets its own directory named after the VM.

```
~/.darwinvm/
└── vms/
    ├── my-linux/
    │   ├── config.json
    │   ├── disk.img
    │   ├── MachineIdentifier
    │   └── NVRAM.efivars
    └── my-macos/
        ├── config.json
        ├── disk.img
        ├── AuxiliaryStorage
        ├── HardwareModel
        └── MachineIdentifier
```

## Per-VM Directory Layout

### Common Files

| File | Description |
|---|---|
| `config.json` | VM configuration (persisted at creation, read at start) |
| `disk.img` | Main disk image (sparse RAW format) |
| `MachineIdentifier` | Unique machine identity (binary, persisted at creation) |
| `darwinvm.pid` | PID lockfile (present only while VM is running) |
| `state.json` | Runtime state with PID and start time (present only while running) |

### macOS-Specific Files

| File | Description |
|---|---|
| `AuxiliaryStorage` | macOS boot environment data (created by `VZMacAuxiliaryStorage`) |
| `HardwareModel` | Hardware model data from IPSW (binary, created at install) |

### Linux-Specific Files

| File | Description |
|---|---|
| `NVRAM.efivars` | EFI variable store (boot order, OS boot entries) |

## config.json Format

The VM configuration is stored as a JSON file. Here is a complete example:

### Linux VM

```json
{
  "cpuCount": 4,
  "createdAt": "2025-01-15T10:30:00Z",
  "diskSizeGB": 64,
  "headless": false,
  "isoPath": "/Users/user/Downloads/ubuntu-24.04-live-server-arm64.iso",
  "memoryGB": 8,
  "name": "my-linux",
  "network": {
    "type": "nat"
  },
  "type": "linux"
}
```

### macOS VM

```json
{
  "cpuCount": 4,
  "createdAt": "2025-01-15T10:30:00Z",
  "diskSizeGB": 64,
  "headless": false,
  "ipswPath": "/Users/user/Downloads/UniversalMac_15.0_Restore.ipsw",
  "memoryGB": 8,
  "name": "my-macos",
  "network": {
    "type": "nat"
  },
  "type": "macos"
}
```

### Bridged Network Example

```json
{
  "network": {
    "interfaceId": "en0",
    "type": "bridged"
  }
}
```

## config.json Fields

| Field | Type | Description |
|---|---|---|
| `name` | String | VM name (matches directory name) |
| `type` | String | `"macos"` or `"linux"` |
| `cpuCount` | Int | Number of virtual CPU cores |
| `memoryGB` | Int | Memory allocation in GB |
| `diskSizeGB` | Int | Disk image size in GB |
| `network` | Object | Network configuration (see below) |
| `headless` | Bool | Default headless mode preference |
| `ipswPath` | String? | Path to IPSW file (macOS only, may be null) |
| `isoPath` | String? | Path to ISO file (Linux only, may be null) |
| `createdAt` | String | ISO 8601 creation timestamp |

### Network Object

| Field | Type | Description |
|---|---|---|
| `type` | String | `"nat"` or `"bridged"` |
| `interfaceId` | String | Bridge interface ID (only present when type is `"bridged"`) |

## state.json Format

The state file exists only while a VM is running:

```json
{
  "pid": 12345,
  "startedAt": "2025-01-15T10:35:00Z"
}
```

| Field | Type | Description |
|---|---|---|
| `pid` | Int | Process ID of the running darwinvm process |
| `startedAt` | String | ISO 8601 timestamp of when the VM was started |

## Disk Images

Disk images are created as sparse RAW files using `ftruncate`. This is the only format supported by Virtualization.framework.

### Sparse Files on APFS

- The file reports its full logical size (e.g., 64 GB) but only consumes actual disk space for written data
- Initial disk usage is near zero
- Space consumption grows as the guest writes data
- APFS handles sparse file storage natively

### Checking Actual Disk Usage

```bash
# Logical size (what the guest sees)
ls -lh ~/.darwinvm/vms/my-linux/disk.img

# Actual disk usage (space consumed on APFS)
du -h ~/.darwinvm/vms/my-linux/disk.img
```

## Manual Configuration Editing

You can manually edit `config.json` to change VM settings when the VM is stopped. Common modifications:

- **Remove ISO after installation:** Set `"isoPath"` to `null`
- **Change CPU/memory:** Update `cpuCount` or `memoryGB` (respecting validation limits)
- **Switch network mode:** Change the `network` object

> **Warning:** Do not modify binary files (`MachineIdentifier`, `HardwareModel`, `AuxiliaryStorage`, `NVRAM.efivars`) manually. These are opaque data used by Virtualization.framework.

> **Warning:** Do not modify `config.json` while the VM is running. Changes will not take effect until the next start, and concurrent writes could corrupt the file.
