# Troubleshooting

## Common Issues

### "not entitled" or Entitlement Errors

**Symptom:** The binary builds and runs, but VM operations fail with errors about missing entitlements.

**Cause:** The binary is not codesigned with the required entitlements.

**Fix:**
```bash
make sign
# Or manually:
codesign --force --sign - --entitlements darwinvm.entitlements .build/release/darwinvm
```

Verify entitlements are present:
```bash
codesign -d --entitlements - .build/release/darwinvm
```

You should see `com.apple.security.virtualization` and `com.apple.vm.networking` in the output.

---

### "VM '<name>' already exists"

**Symptom:** `darwinvm create` fails because a VM with that name already exists.

**Fix:** Choose a different name, or delete the existing VM:
```bash
darwinvm delete <name>
```

---

### "VM '<name>' is already running"

**Symptom:** `darwinvm start` fails because the VM appears to be running.

**Possible causes:**
1. The VM is actually running in another terminal
2. A stale PID file exists from a crashed process

**Fix:**

Check if the process is actually running:
```bash
cat ~/.darwinvm/vms/<name>/darwinvm.pid
ps aux | grep <pid>
```

If the process is not running (stale PID file), remove it:
```bash
rm ~/.darwinvm/vms/<name>/darwinvm.pid
rm ~/.darwinvm/vms/<name>/state.json
```

---

### "VM '<name>' is not running"

**Symptom:** `darwinvm stop` fails because the VM is not running.

**Cause:** The VM has already stopped, or the PID file was cleaned up.

**Fix:** No action needed. The VM is already stopped.

---

### macOS Installation Fails

**Symptom:** `darwinvm create --type macos --ipsw <path>` fails during installation.

**Possible causes:**

1. **Incompatible IPSW:** The restore image is not supported on your hardware
   - Check: Use an IPSW for the same or newer macOS version as your host
   - Check: Ensure it's a Universal Mac restore image (not iPhone/iPad)

2. **Insufficient resources:** CPU or memory below the IPSW's minimum requirements
   - DarwinVM automatically bumps values to minimums, but if host resources are too low, creation will fail
   - Check: Ensure your Mac has enough RAM and CPU cores

3. **Disk space:** Not enough free disk space for the installation
   - macOS installation typically needs 30+ GB of working space

**Fix:** Try a different IPSW, increase resources, or free up disk space.

---

### Linux VM Doesn't Boot

**Symptom:** The VM starts but shows a blank screen or EFI shell.

**Possible causes:**

1. **Wrong architecture:** Using an x86_64 ISO instead of ARM64/aarch64
   - Fix: Download the ARM64 variant of your Linux distribution

2. **ISO not attached:** The ISO path in config.json is incorrect or the file was moved
   - Fix: Check `~/.darwinvm/vms/<name>/config.json` and verify `isoPath` points to a valid file

3. **EFI boot order:** After installation, the EFI boot order may not point to the installed OS
   - Fix: In the EFI shell, navigate to the boot entry manually, or reinstall

---

### No Serial Console Output in Headless Mode

**Symptom:** Starting with `--headless` shows no output.

**Cause:** The guest OS is not configured to use the serial console.

**Fix for Linux:** Add `console=ttyAMA0` to the kernel command line. For GRUB-based distributions:

1. Edit `/etc/default/grub` in the guest:
   ```
   GRUB_CMDLINE_LINUX="console=ttyAMA0"
   GRUB_TERMINAL="serial console"
   ```
2. Run `update-grub` and reboot

**Fix for macOS:** macOS does not support serial console output in the same way. Use GUI mode or SSH instead.

---

### VM Doesn't Stop Gracefully

**Symptom:** `darwinvm stop` sends SIGTERM but the VM doesn't shut down.

**Cause:** The guest OS may not respond to the ACPI power button event (`vm.requestStop()`).

**Fix:** Use force stop:
```bash
darwinvm stop <name> --force
```

This sends SIGKILL, immediately terminating the process.

---

### Bridge Interface Not Found

**Symptom:** Warning "Bridge interface '<iface>' not found, falling back to NAT."

**Cause:** The specified network interface doesn't exist or has a different name.

**Fix:** List available interfaces:
```bash
networksetup -listallhardwareports
# Or
ifconfig -l
```

Then use the correct interface name:
```bash
darwinvm create my-vm --type linux --iso ubuntu.iso --network bridged:en0
```

---

### "Validation failed: Memory X GB exceeds 80% of host RAM"

**Cause:** You requested more memory than 80% of your Mac's physical RAM.

**Fix:** Reduce the `--mem` value. For example, on a 16 GB Mac, the maximum is 12 GB:
```bash
darwinvm create my-vm --type linux --iso ubuntu.iso --mem 12
```

---

### "Validation failed: Disk size X GB exceeds 90% of free disk space"

**Cause:** You requested a disk larger than 90% of available disk space.

**Fix:** Free up disk space or reduce `--disk`:
```bash
# Check available space
df -h ~

# Create with smaller disk
darwinvm create my-vm --type linux --iso ubuntu.iso --disk 32
```

> Note: Disk images are sparse, so a 64 GB disk doesn't immediately consume 64 GB. However, validation ensures you have headroom for growth.

---

## Diagnostic Commands

### Check VM Configuration

```bash
cat ~/.darwinvm/vms/<name>/config.json | python3 -m json.tool
```

### Check if a VM is Running

```bash
cat ~/.darwinvm/vms/<name>/darwinvm.pid 2>/dev/null && echo "PID file exists" || echo "Not running"
```

### Check Actual Disk Usage

```bash
# Logical size
ls -lh ~/.darwinvm/vms/<name>/disk.img

# Actual usage on disk
du -h ~/.darwinvm/vms/<name>/disk.img

# Total VM directory size
du -sh ~/.darwinvm/vms/<name>/
```

### Verify Binary Entitlements

```bash
codesign -d --entitlements - $(which darwinvm)
```

### List All VM Directories

```bash
ls -la ~/.darwinvm/vms/
```

### Clean Up Stale State

If a VM process crashed without cleaning up:
```bash
rm ~/.darwinvm/vms/<name>/darwinvm.pid
rm ~/.darwinvm/vms/<name>/state.json
```
