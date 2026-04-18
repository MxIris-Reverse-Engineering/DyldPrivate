# swift-dyld-private

Provides Swift bindings for Apple's private dyld SPIs (`dyld_priv.h`, `dyld_introspection.h`, `dyld_process_info.h`, `utils_priv.h`) while keeping C symbol names out of the compiled binary. Every dyld function is resolved at runtime via `dlsym` with compile-time string obfuscation using the `#Obfuscate` macro from `swift-confidential`, eliminating plaintext symbol names from the binary footprint.

## Architecture

The package consists of two complementary layers:

**DyldPrivateC** — A C umbrella that directly exposes the vendored Apple private headers. Use this target if you need direct C-level access to dyld internals without the Swift wrapper overhead.

**DyldPrivate** — The primary Swift layer wraps every `extern` C function via `dlsym` and obfuscated symbol lookup. No dyld symbol names (e.g., `dyld_shared_cache_file_path`) or fallback paths (e.g., `/usr/lib/system/libdyld.dylib`) appear unencrypted in the compiled binary.

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/<your-org>/swift-dyld-private.git", from: "1.0.0"),
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "DyldPrivate", package: "swift-dyld-private"),
            // Or, for direct C access:
            // .product(name: "DyldPrivateC", package: "swift-dyld-private"),
        ]
    ),
]
```

## Usage

Import the library and call dyld functions through the `DyldPriv` namespace:

```swift
import DyldPrivate

// Get the path to the shared cache
if let path = DyldPriv.sharedCacheFilePath() {
    print("Shared cache path: \(path)")
}

// Query the shared cache memory range
if let range = DyldPriv.sharedCacheRange() {
    print("Shared cache mapped at \(range.pointer) with size \(range.size) bytes")
}

// Introspect per-image information
let dlsymHandle = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "dlsym")!
if let header = DyldPriv.imageHeader(containing: UnsafeRawPointer(dlsymHandle)) {
    let installName = MachOUtils.installName(of: header.assumingMemoryBound(to: mach_header.self))
    print("dlsym is provided by \(installName ?? "<unknown>")")
}
```

## Obfuscation Guarantee

Every dyld symbol name is compiled into the binary in obfuscated form. The build system enforces this through `Tests/DyldPrivateTests/ObfuscationAuditTests.swift`, which scans every compiled `.o` file for plaintext occurrences of forbidden symbols. If a change accidentally leaks an unencrypted dyld name or path, the audit test fails before the code can merge.

You can verify obfuscation yourself on a built binary:

```bash
strings .build/arm64-apple-macosx/debug/DyldPrivate.build/*.o | grep dyld_shared_cache_file_path
# Expected: (no output)
```

## Prior Art

The runtime symbol resolution and obfuscation strategy is adapted from the MachOKit project's runtime-shim pattern. See https://github.com/p-x9/MachOKit/pull/272 for detailed discussion of the approach.

## Requirements

- Swift 6.2 or later
- Apple platforms: iOS 13+, macOS 10.15+, macCatalyst 15+, watchOS 8+, tvOS 15+, visionOS 1+

## License

Apple Public Source License 2.0. This package vendors Apple's dyld headers under `Sources/DyldPrivateC/include/mach-o/` as provided by the Apple open-source distribution.
