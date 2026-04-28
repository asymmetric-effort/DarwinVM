# CLI Reference

DarwinVM provides five subcommands for full VM lifecycle management.

## Global Options

```
-h, --help    Show help information
```

## darwinvm create

Create a new virtual machine.

```
darwinvm create <name> --type <macos|linux> [options]
```

### Arguments

| Argument | Description |
|---|---|
| `<name>` | Name of the virtual machine (must be unique) |

### Options

| Option | Default | Description |
|---|---|---|
| `--type <type>` | (required) | VM type: `macos` or `linux` |
| `--ipsw <path>` | — | Path to macOS IPSW restore image (required for macOS) |
| `--iso <path>` | — | Path to Linux ISO installer image |
| `--cpu <N>` | `2` | Number of CPU cores |
| `--mem <N>` | `4` | Memory in GB |
| `--disk <N>` | `64` | Disk size in GB |
| `--network <mode>` | `nat` | Network mode: `nat` or `bridged:<interface>` |
| `--headless` | `false` | Default to headless mode on start |

### Validation Rules

- `--cpu`: 1 to host processor count
- `--mem`: 4 GB minimum, 80% of host physical memory maximum (also capped by Virtualization.framework's `maximumAllowedMemorySize`)
- `--disk`: 1 GB minimum, 90% of free disk space maximum

### Examples

```bash
# Create a Linux VM with defaults
darwinvm create my-linux --type linux --iso ~/Downloads/ubuntu.iso

# Create a macOS VM from IPSW
darwinvm create my-macos --type macos --ipsw ~/Downloads/UniversalMac_15.0_Restore.ipsw

# Create with custom resources
darwinvm create dev-server --type linux --iso ~/Downloads/debian.iso \
    --cpu 8 --mem 16 --disk 128

# Create with bridged networking
darwinvm create bridged-vm --type linux --iso ~/Downloads/ubuntu.iso \
    --network bridged:en0
```

### Notes

- **macOS VMs:** The `create` command installs macOS from the IPSW during creation. This can take 15–30 minutes.
- **Linux VMs:** The ISO is recorded in the config but only attached on the first `start`. Creation is fast (seconds).
- Disk images are created as sparse files (near-zero initial disk usage on APFS).

---

## darwinvm start

Start an existing virtual machine.

```
darwinvm start <name> [--headless]
```

### Arguments

| Argument | Description |
|---|---|
| `<name>` | Name of the virtual machine to start |

### Options

| Option | Description |
|---|---|
| `--headless` | Run in headless mode (serial console on stdin/stdout) |

### Behavior

1. Loads the VM configuration from `~/.darwinvm/vms/<name>/config.json`
2. Checks that the VM is not already running (via PID file)
3. Builds the Virtualization.framework configuration
4. For Linux VMs with an ISO path, attaches the ISO on first boot
5. Writes a PID file and starts the VM
6. In GUI mode: opens a native window with the VM display
7. In headless mode: wires serial console to stdin/stdout

### Examples

```bash
# Start with GUI window
darwinvm start my-linux

# Start in headless mode (serial console)
darwinvm start my-linux --headless
```

---

## darwinvm stop

Stop a running virtual machine.

```
darwinvm stop <name> [--force]
```

### Arguments

| Argument | Description |
|---|---|
| `<name>` | Name of the virtual machine to stop |

### Options

| Option | Description |
|---|---|
| `--force` | Send SIGKILL instead of SIGTERM (immediate kill) |

### Behavior

1. Reads the PID from `~/.darwinvm/vms/<name>/darwinvm.pid`
2. Verifies the process is still running
3. Sends SIGTERM (graceful) or SIGKILL (force)
4. The running VM process handles SIGTERM by calling `vm.requestStop()` for a clean guest shutdown
5. Waits up to 3 seconds for the process to exit
6. Cleans up the PID file on success

### Examples

```bash
# Graceful shutdown
darwinvm stop my-linux

# Force kill
darwinvm stop my-linux --force
```

---

## darwinvm list

List all virtual machines.

```
darwinvm list
```

### Output Columns

| Column | Description |
|---|---|
| NAME | VM name |
| TYPE | `macos` or `linux` |
| CPU | Number of CPU cores |
| MEM | Memory in GB |
| DISK | Disk size in GB |
| STATUS | `running` or `stopped` |
| NETWORK | `nat` or `bridged:<interface>` |

### Example Output

```
NAME                  TYPE      CPU    MEM     DISK    STATUS      NETWORK
my-linux              linux     4      8GB     64GB    running     nat
dev-server            linux     8      16GB    128GB   stopped     bridged:en0
my-macos              macos     4      8GB     64GB    stopped     nat
```

---

## darwinvm delete

Delete a virtual machine and all its data.

```
darwinvm delete <name> [--force]
```

### Arguments

| Argument | Description |
|---|---|
| `<name>` | Name of the virtual machine to delete |

### Options

| Option | Description |
|---|---|
| `--force` | Skip confirmation prompt and force-stop the VM if running |

### Behavior

1. Checks if the VM is running
   - Without `--force`: returns an error if running
   - With `--force`: sends SIGKILL and waits for exit
2. Without `--force`: prompts for confirmation (`y/N`)
3. Removes the entire VM directory (`~/.darwinvm/vms/<name>/`)

### Examples

```bash
# Delete with confirmation
darwinvm delete my-linux

# Force delete (no prompt, kills if running)
darwinvm delete my-linux --force
```

> **Warning:** Deletion is permanent and cannot be undone. All VM data including disk images is removed.
