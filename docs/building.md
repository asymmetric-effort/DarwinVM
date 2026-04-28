# Building

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon (M1 or later)
- Swift 6.0+ toolchain (Xcode Command Line Tools or Xcode)

## Build Commands

The project includes a Makefile for common operations:

| Command | Description |
|---|---|
| `make build` | Debug build |
| `make release` | Release build (optimized) |
| `make sign` | Codesign with entitlements (runs release build first) |
| `make install` | Install to `/usr/local/bin` (runs sign first) |
| `make uninstall` | Remove from `/usr/local/bin` |
| `make test` | Run unit tests |
| `make clean` | Remove build artifacts |

### Direct SPM Commands

You can also use Swift Package Manager directly:

```bash
swift build                  # Debug build
swift build -c release       # Release build
swift test                   # Run tests
swift package clean          # Clean
```

## Code Signing and Entitlements

### Why Code Signing Is Required

Apple's Virtualization.framework requires specific entitlements to operate:

| Entitlement | Purpose |
|---|---|
| `com.apple.security.virtualization` | Required for all VM operations |
| `com.apple.vm.networking` | Required for bridged networking |

Without these entitlements, any attempt to create or start a VM will fail at runtime.

### The Entitlements File

The entitlements are defined in `darwinvm.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.virtualization</key>
    <true/>
    <key>com.apple.vm.networking</key>
    <true/>
</dict>
</plist>
```

### Ad-Hoc Signing

By default, `make sign` uses ad-hoc signing (identity `-`):

```bash
make sign
# Equivalent to:
codesign --force --sign - --entitlements darwinvm.entitlements .build/release/darwinvm
```

This is sufficient for local use on the machine where the binary is built.

### Custom Signing Identity

To sign with a Developer ID certificate:

```bash
make sign IDENTITY="Developer ID Application: Your Name (TEAMID)"
```

Or directly:

```bash
codesign --force --sign "Developer ID Application: Your Name (TEAMID)" \
    --entitlements darwinvm.entitlements \
    .build/release/darwinvm
```

### Verifying the Signature

```bash
# Check that entitlements are present
codesign -d --entitlements - .build/release/darwinvm

# Verify the signature
codesign --verify --verbose .build/release/darwinvm
```

## Installation

### Default Installation

```bash
sudo make install
```

This installs the signed binary to `/usr/local/bin/darwinvm`.

### Custom Prefix

```bash
sudo make install PREFIX=/opt/darwinvm
```

### Uninstall

```bash
sudo make uninstall
```

## Package Structure

```
Package.swift                 # SPM manifest
├── Products
│   ├── darwinvm             # CLI executable
│   └── DarwinVMCore         # Library (reusable core)
├── Dependencies
│   ├── swift-argument-parser # CLI parsing
│   └── swift-testing         # Test framework (test target only)
└── Targets
    ├── darwinvm             # Executable (depends on DarwinVMCore + ArgumentParser)
    ├── DarwinVMCore         # Library (depends on Virtualization.framework)
    └── DarwinVMCoreTests    # Tests (depends on DarwinVMCore + Testing)
```

## Platform Configuration

The package requires macOS 14.0+:

```swift
platforms: [.macOS(.v14)]
```

This is the minimum version that supports the Virtualization.framework features used by DarwinVM (VZVirtioGraphicsDeviceConfiguration, VZGenericMachineIdentifier, etc.).

## Troubleshooting Build Issues

### "no such module 'Virtualization'"

Ensure you're building on macOS 14.0+ with an Apple Silicon Mac. The Virtualization framework is only available on these platforms.

### "no such module 'XCTest'" or "no such module 'Testing'"

Tests use the `swift-testing` package. Run `swift package resolve` to fetch dependencies. If using Xcode Command Line Tools without Xcode, ensure the swift-testing dependency is in `Package.swift`.

### Codesigning Fails

Ad-hoc signing (`-`) should work without any certificates. If it fails, check:
- The binary exists at `.build/release/darwinvm`
- The entitlements file exists at `darwinvm.entitlements`
- You have permission to write to the binary

### Runtime "not entitled" Errors

If the binary runs but VM operations fail with entitlement errors:
1. Verify the binary is signed: `codesign -d --entitlements - .build/release/darwinvm`
2. Re-sign if needed: `make sign`
3. If running from Xcode, add the entitlements to the scheme's signing configuration
