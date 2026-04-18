# swift-dyld-private: Full C-API Obfuscated Wrapping Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the package to `swift-dyld-private` and wrap every `extern` C function exposed through the private dyld headers behind an obfuscated Swift layer that resolves symbols at runtime via `dlsym`, so static analysis of the compiled binary reveals no references to dyld private symbol names.

**Architecture:** Two-layer Swift Package.
- **Layer 1 (`DyldPrivateC`)** — the existing C umbrella module exposing `dyld_priv.h`, `dyld_introspection.h`, `dyld_process_info.h`, `utils_priv.h`, `dyld-interposing.h`, `dyld_cache_format.h`, and `function-variant-macros.h`. Consumers that *want* direct linkage can import it; nothing in this layer changes except the target name.
- **Layer 2 (`DyldPrivate`)** — a Swift target that `@_exported import DyldPrivateC` for type re-export, uses `ConfidentialKit`'s `#Obfuscate` macro to keep all symbol name strings out of the binary, and routes every C entry point through `DyldSymbolResolver` (`dlsym(RTLD_DEFAULT)` with `dlopen("/usr/lib/system/libdyld.dylib")` fallback). Public Swift APIs live in per-header enums (`DyldPriv`, `DyldIntrospection`, `DyldProcessInfo`, `MachOUtils`).

**Tech Stack:**
- Swift 6.2 toolchain, SPM, Swift Testing
- [`securevale/swift-confidential`](https://github.com/securevale/swift-confidential) 0.5.x (`ConfidentialKit` product) — `#Obfuscate` macro
- `Darwin` module (`dlsym`, `dlopen`, `RTLD_*`)
- Reference PR: [`p-x9/MachOKit#272`](https://github.com/p-x9/MachOKit/pull/272) (runtime shim pattern)

**Obfuscation guarantee:** After the plan is complete, `strings` over every product `.o` must show **zero** matches for: each wrapped symbol name, `/usr/lib/system/libdyld.dylib`, `libdyld.dylib`, and `/usr/lib/system`. Task 4 codifies this as an automated test.

---

## File Structure (end state)

```
swift-dyld-private/
├── Package.swift                                       # Package name: swift-dyld-private
├── Sources/
│   ├── DyldPrivateC/                                   # (renamed from Sources/DyldPrivate)
│   │   ├── dummy.c
│   │   └── include/
│   │       └── mach-o/*.h                              # unchanged
│   └── DyldPrivate/                                    # (renamed from Sources/DyldPrivateRuntime)
│       ├── Obfuscation/
│       │   ├── ObfuscatedDyldSymbols.swift             # all symbol-name literals, one #Obfuscate block per header group
│       │   └── DyldSymbolResolver.swift                # dlsym + libdyld fallback
│       ├── Exports.swift                               # @_exported import DyldPrivateC
│       ├── API/
│       │   ├── DyldPriv+Atfork.swift                   # _dyld_atfork_*, _dyld_fork_child, _dyld_dlopen_atfork_*
│       │   ├── DyldPriv+ObjCNotify.swift               # _dyld_objc_notify_register, _dyld_objc_register_callbacks
│       │   ├── DyldPriv+Image.swift                    # image header/path/slide/uuid helpers
│       │   ├── DyldPriv+Platform.swift                 # dyld_get_active_platform, dyld_sdk_at_least, etc.
│       │   ├── DyldPriv+Version.swift                  # dyld_get_*_version, dyld_*_version_token_*
│       │   ├── DyldPriv+SharedCache.swift              # dyld_shared_cache_*, _dyld_get_shared_cache_*
│       │   ├── DyldPriv+Runtime.swift                  # _dyld_launch_mode, dyld_need_closure, etc.
│       │   ├── DyldPriv+Interpose.swift                # dyld_dynamic_interpose
│       │   ├── DyldPriv+Unwind.swift                   # _dyld_find_unwind_sections, dyld_stub_binder (documented skip)
│       │   ├── DyldIntrospection.swift                 # all of dyld_introspection.h
│       │   ├── DyldProcessInfo.swift                   # all of dyld_process_info.h
│       │   └── MachOUtils.swift                        # all of utils_priv.h
│       └── Internal/
│           └── TypedFunctionPointers.swift             # typealias for every @convention(c) signature used
└── Tests/
    ├── DyldPrivateCTests/                              # (renamed from DyldPrivateTests)
    │   └── DyldPrivateCTests.swift
    └── DyldPrivateTests/                               # (renamed from DyldPrivateRuntimeTests)
        ├── DyldPrivateTests.swift                      # runtime behavior tests
        ├── ObfuscationAuditTests.swift                 # strings-scan test (build-time checker)
        └── Fixtures/
            └── SymbolProbe.swift                       # knownSymbolProbe helper used by multiple tests
```

**Rule of thumb:** each `DyldPriv+*.swift` file covers ≤ 15 functions. If a group grows larger, split further rather than stretching a single file.

---

## Phase A — Package rename & restructure

### Task 1: Rename `Package.swift` to `swift-dyld-private` and split targets

**Files:**
- Modify: `Package.swift`

- [ ] **Step 1.1: Read current Package.swift**

Run: `cat Package.swift`
Expected: current package name `DyldPrivate`, targets `DyldPrivate` (C) + `DyldPrivateRuntime` (Swift) + matching test targets.

- [ ] **Step 1.2: Rewrite Package.swift with new names**

Replace the file with:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "swift-dyld-private",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .macCatalyst(.v15),
        .watchOS(.v8),
        .tvOS(.v15),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "DyldPrivate",
            targets: ["DyldPrivate"]
        ),
        .library(
            name: "DyldPrivateC",
            targets: ["DyldPrivateC"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/securevale/swift-confidential.git", .upToNextMinor(from: "0.5.0")),
    ],
    targets: [
        .target(
            name: "DyldPrivateC"
        ),
        .target(
            name: "DyldPrivate",
            dependencies: [
                "DyldPrivateC",
                .product(name: "ConfidentialKit", package: "swift-confidential"),
            ]
        ),
        .testTarget(
            name: "DyldPrivateCTests",
            dependencies: ["DyldPrivateC"]
        ),
        .testTarget(
            name: "DyldPrivateTests",
            dependencies: ["DyldPrivate"]
        ),
    ]
)
```

- [ ] **Step 1.3: Commit (rename only, before file moves)**

```bash
git add Package.swift
git commit -m "chore: rename package to swift-dyld-private with DyldPrivate/DyldPrivateC split"
```

---

### Task 2: Move source folders to match new target names

**Files:**
- Rename: `Sources/DyldPrivate/` → `Sources/DyldPrivateC/`
- Rename: `Sources/DyldPrivateRuntime/` → `Sources/DyldPrivate/`
- Rename: `Tests/DyldPrivateTests/` → `Tests/DyldPrivateCTests/`
- Rename: `Tests/DyldPrivateRuntimeTests/` → `Tests/DyldPrivateTests/`

- [ ] **Step 2.1: Move C sources**

```bash
git mv Sources/DyldPrivate Sources/DyldPrivateC
```

- [ ] **Step 2.2: Move Swift sources**

```bash
git mv Sources/DyldPrivateRuntime Sources/DyldPrivate
```

- [ ] **Step 2.3: Move C tests**

```bash
git mv Tests/DyldPrivateTests Tests/DyldPrivateCTests
```

- [ ] **Step 2.4: Move Swift tests**

```bash
git mv Tests/DyldPrivateRuntimeTests Tests/DyldPrivateTests
```

- [ ] **Step 2.5: Fix test imports**

Edit `Tests/DyldPrivateCTests/DyldPrivateTests.swift` (the file inside the *new* `DyldPrivateCTests/` directory — keep the .swift filename as-is for now, we'll rename it next step):

```swift
import Testing
@testable import DyldPrivateC

@Test func example() async throws {
}
```

And rename the file: `git mv Tests/DyldPrivateCTests/DyldPrivateTests.swift Tests/DyldPrivateCTests/DyldPrivateCTests.swift`

- [ ] **Step 2.6: Update Swift test file imports**

In `Tests/DyldPrivateTests/DyldPrivateRuntimeTests.swift`, change `@testable import DyldPrivateRuntime` to `@testable import DyldPrivate`, then:

```bash
git mv Tests/DyldPrivateTests/DyldPrivateRuntimeTests.swift Tests/DyldPrivateTests/DyldPrivateTests.swift
```

- [ ] **Step 2.7: Build to prove layout compiles**

Run: `swift build 2>&1 | xcsift`
Expected: `"status": "success"` and no warnings.

- [ ] **Step 2.8: Run tests**

Run: `swift test 2>&1 | xcsift`
Expected: `"status": "success"`, all existing tests (including the 4 runtime tests) pass.

- [ ] **Step 2.9: Commit**

```bash
git add -A
git commit -m "refactor: move sources to match renamed targets (DyldPrivateC + DyldPrivate)"
```

---

## Phase B — Foundation layer

### Task 3: Re-export C types from Swift layer

**Files:**
- Create: `Sources/DyldPrivate/Exports.swift`

- [ ] **Step 3.1: Write the failing test**

Create `Tests/DyldPrivateTests/ExportsTests.swift`:

```swift
#if canImport(Darwin)
import Testing
import DyldPrivate

@Test
func machHeaderTypeIsReExportedFromSwiftModule() {
    // If the @_exported import works, `mach_header` resolves via `import DyldPrivate` alone.
    let header = mach_header()
    #expect(header.magic == 0)
}
#endif
```

- [ ] **Step 3.2: Run to verify it fails**

Run: `swift test --filter ExportsTests 2>&1 | xcsift`
Expected: FAIL with "cannot find type 'mach_header' in scope".

- [ ] **Step 3.3: Create Exports.swift**

```swift
#if canImport(Darwin)
@_exported import DyldPrivateC
@_exported import Darwin.Mach
#endif
```

- [ ] **Step 3.4: Run to verify it passes**

Run: `swift test --filter ExportsTests 2>&1 | xcsift`
Expected: PASS.

- [ ] **Step 3.5: Commit**

```bash
git add Sources/DyldPrivate/Exports.swift Tests/DyldPrivateTests/ExportsTests.swift
git commit -m "feat(DyldPrivate): re-export C types from DyldPrivateC"
```

---

### Task 4: Obfuscation audit test (build-time static-analysis check)

**Files:**
- Create: `Tests/DyldPrivateTests/ObfuscationAuditTests.swift`
- Create: `Tests/DyldPrivateTests/Fixtures/ForbiddenSymbolList.swift`

- [ ] **Step 4.1: Write the failing test**

Create `Tests/DyldPrivateTests/Fixtures/ForbiddenSymbolList.swift`:

```swift
#if canImport(Darwin)
enum ForbiddenSymbolList {
    static let names: [String] = [
        "dyld_shared_cache_file_path",
        "_dyld_get_shared_cache_range",
        "dyld_image_header_containing_address",
        "dyld_image_path_containing_address",
        "/usr/lib/system/libdyld.dylib",
        "libdyld.dylib",
    ]
}
#endif
```

Create `Tests/DyldPrivateTests/ObfuscationAuditTests.swift`:

```swift
#if canImport(Darwin)
import Foundation
import Testing

@Test
func noForbiddenSymbolsInBuiltObjects() throws {
    let buildDirectory = try #require(ProcessInfo.processInfo.environment["BUILT_PRODUCTS_DIR"]
        ?? findBuildDirectory())
    let objectPaths = try objectFilePaths(in: buildDirectory)
    #expect(!objectPaths.isEmpty, "no .o files found under \(buildDirectory)")

    for objectPath in objectPaths {
        let fileData = try Data(contentsOf: URL(fileURLWithPath: objectPath))
        for forbidden in ForbiddenSymbolList.names {
            #expect(
                !fileData.contains(Data(forbidden.utf8)),
                "forbidden literal \(forbidden) found in \(objectPath)"
            )
        }
    }
}

private func findBuildDirectory() -> String? {
    let fileManager = FileManager.default
    let workingDirectory = fileManager.currentDirectoryPath
    let candidate = "\(workingDirectory)/.build/arm64-apple-macosx/debug/DyldPrivate.build"
    return fileManager.fileExists(atPath: candidate) ? candidate : nil
}

private func objectFilePaths(in directory: String) throws -> [String] {
    let enumerator = FileManager.default.enumerator(atPath: directory)
    var results: [String] = []
    while let relativePath = enumerator?.nextObject() as? String {
        guard relativePath.hasSuffix(".o") else { continue }
        results.append("\(directory)/\(relativePath)")
    }
    return results
}
#endif
```

- [ ] **Step 4.2: Run to verify it passes (current symbols are already obfuscated)**

Run: `swift test --filter ObfuscationAuditTests 2>&1 | xcsift`
Expected: PASS (the four existing symbols are already obfuscated; the libdyld path too).

- [ ] **Step 4.3: Add a deliberate negative control and remove it**

Temporarily add a plain `let forbidden = "dyld_shared_cache_file_path"` to any Swift file in `Sources/DyldPrivate/`.
Run the audit — expect FAIL. Remove the line. Re-run — expect PASS.
This proves the audit actually detects leaks.

- [ ] **Step 4.4: Commit**

```bash
git add Tests/DyldPrivateTests/ObfuscationAuditTests.swift Tests/DyldPrivateTests/Fixtures/ForbiddenSymbolList.swift
git commit -m "test: add obfuscation audit that scans .o files for forbidden dyld symbol literals"
```

**Maintenance rule:** every time a new symbol is added to `ObfuscatedDyldSymbols`, the corresponding entry must also be added to `ForbiddenSymbolList.names`. This is enforced by inspection in code review — no runtime check required.

---

### Task 5: Reorganize existing runtime files

**Files:**
- Move: `Sources/DyldPrivate/ObfuscatedDyldSymbols.swift` → `Sources/DyldPrivate/Obfuscation/ObfuscatedDyldSymbols.swift`
- Move: `Sources/DyldPrivate/DyldSymbolResolver.swift` → `Sources/DyldPrivate/Obfuscation/DyldSymbolResolver.swift`
- Move: `Sources/DyldPrivate/DyldRuntime.swift` → `Sources/DyldPrivate/API/DyldPriv+SharedCache.swift` (partial, see Task 8+)
- Create: `Sources/DyldPrivate/Internal/TypedFunctionPointers.swift`

- [ ] **Step 5.1: Create subdirectories**

```bash
mkdir -p Sources/DyldPrivate/Obfuscation Sources/DyldPrivate/API Sources/DyldPrivate/Internal
```

- [ ] **Step 5.2: Move obfuscation files**

```bash
git mv Sources/DyldPrivate/ObfuscatedDyldSymbols.swift Sources/DyldPrivate/Obfuscation/ObfuscatedDyldSymbols.swift
git mv Sources/DyldPrivate/DyldSymbolResolver.swift Sources/DyldPrivate/Obfuscation/DyldSymbolResolver.swift
```

- [ ] **Step 5.3: Move runtime file and rename to reflect content**

```bash
git mv Sources/DyldPrivate/DyldRuntime.swift Sources/DyldPrivate/API/DyldPriv+SharedCache.swift
```

- [ ] **Step 5.4: Rename the exported enum inside the moved file**

Edit `Sources/DyldPrivate/API/DyldPriv+SharedCache.swift`: rename `public enum DyldRuntime` to `public enum DyldPriv` and move the two shared-cache methods into a nested extension that sits alongside future grouped extensions:

```swift
#if canImport(Darwin)
import Darwin

public enum DyldPriv {}

extension DyldPriv {
    public typealias SharedCacheFilePathFunction = @convention(c) () -> UnsafePointer<CChar>?
    public typealias SharedCacheRangeFunction = @convention(c) (UnsafeMutablePointer<Int>?) -> UnsafeRawPointer?

    private static let sharedCacheFilePathFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldSymbols.$sharedCacheFilePath,
        as: SharedCacheFilePathFunction.self
    )

    private static let sharedCacheRangeFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldSymbols.$sharedCacheRange,
        as: SharedCacheRangeFunction.self
    )

    public static func sharedCacheFilePath() -> String? {
        guard let function = sharedCacheFilePathFunction,
              let pointer = function()
        else {
            return nil
        }
        return String(cString: pointer)
    }

    public static func sharedCacheRange() -> (pointer: UnsafeRawPointer, size: Int)? {
        guard let function = sharedCacheRangeFunction else {
            return nil
        }
        var size = 0
        guard let pointer = withUnsafeMutablePointer(to: &size, { function($0) }) else {
            return nil
        }
        return (pointer, size)
    }
}

#endif
```

- [ ] **Step 5.5: Create empty `DyldPriv+Image.swift` with the two image helpers**

Create `Sources/DyldPrivate/API/DyldPriv+Image.swift` — move `imageHeader(containing:)` and `imagePath(containing:)` out of the old `DyldRuntime.swift` into here:

```swift
#if canImport(Darwin)
import Darwin

extension DyldPriv {
    public typealias ImageHeaderContainingAddressFunction = @convention(c) (UnsafeRawPointer?) -> UnsafeRawPointer?
    public typealias ImagePathContainingAddressFunction = @convention(c) (UnsafeRawPointer?) -> UnsafePointer<CChar>?

    private static let imageHeaderContainingAddressFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldSymbols.$imageHeaderContainingAddress,
        as: ImageHeaderContainingAddressFunction.self
    )

    private static let imagePathContainingAddressFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldSymbols.$imagePathContainingAddress,
        as: ImagePathContainingAddressFunction.self
    )

    public static func imageHeader(containing address: UnsafeRawPointer) -> UnsafeRawPointer? {
        guard let function = imageHeaderContainingAddressFunction else {
            return nil
        }
        return function(address)
    }

    public static func imagePath(containing address: UnsafeRawPointer) -> String? {
        guard let function = imagePathContainingAddressFunction,
              let pointer = function(address)
        else {
            return nil
        }
        return String(cString: pointer)
    }
}
#endif
```

- [ ] **Step 5.6: Update existing tests to reference `DyldPriv` instead of `DyldRuntime`**

Edit `Tests/DyldPrivateTests/DyldPrivateTests.swift` — replace every `DyldRuntime.` with `DyldPriv.`.

- [ ] **Step 5.7: Build + test**

Run: `swift test 2>&1 | xcsift`
Expected: all tests pass.

- [ ] **Step 5.8: Commit**

```bash
git add -A
git commit -m "refactor: reorganize runtime into Obfuscation/ and API/ subtrees, introduce DyldPriv namespace"
```

---

## Phase C — Wrap every C entry point, header by header

**Pattern for every function (memorize this — each task applies it):**

1. Append the C symbol name to the matching `#Obfuscate` block inside `Sources/DyldPrivate/Obfuscation/ObfuscatedDyldSymbols.swift` (group literals by source header using one enum per header).
2. Add the same string to `Tests/DyldPrivateTests/Fixtures/ForbiddenSymbolList.swift`.
3. Declare a `public typealias` for the `@convention(c)` function signature in the target `API` extension (keep it `public` so callers can hand off the raw pointer if they want).
4. Lazily resolve the function pointer at file scope via `DyldSymbolResolver.resolve(symbol: ObfuscatedDyldSymbols.$name, as: TypealiasName.self)`.
5. Expose a **Swift-idiomatic wrapper** (returns `String?` instead of `UnsafePointer<CChar>?`, surfaces `Bool` instead of return-through-pointer-plus-bool, turns blocks into `@escaping` Swift closures, `Result<_, DyldError>` where a `kern_return_t*` out-parameter would be awkward).
6. Write one Swift-testing `@Test` per wrapper. **Minimum bar:** the function pointer resolves (not nil) *and*, if the function can be invoked safely from a test harness (no side-effects on host dyld state), call it and assert a sanity-preserving expectation (non-empty string, non-zero size, etc.). Skip live invocation for registration/disposal/notification APIs — only assert non-nil resolution.
7. `swift test --filter <NewTest>` → green, then `swift test --filter ObfuscationAuditTests` → still green, then commit.

**Function-signature crib sheet (translate once, reuse):**

| C return / param                              | Swift wrapper return / param                  |
|-----------------------------------------------|-----------------------------------------------|
| `const char*`                                 | `String?` (wrap with `String(cString:)`)      |
| `bool`                                        | `Bool`                                        |
| `void`                                        | `Void`                                        |
| `const struct mach_header*`                   | `UnsafePointer<mach_header>?`                 |
| `uuid_t` (out param)                          | `uuid_t?` (capture into a local, return)      |
| `void (^block)(…)`                            | `@escaping (…) -> Void`, bridged via `withoutActuallyEscaping`-free direct pass (blocks are `@convention(block)` — see Task 6 template) |
| `kern_return_t* kr` out-param                 | `Result<T, DyldError>` with `.failure(.mach(kern_return_t))` |
| `size_t* length` out-param                    | Swift tuple `(pointer, size)` (already in Task 5) |

**Blocks:** a `void (^)(…)` parameter in C becomes `@convention(block) (…) -> Void` in Swift. Swift closures do not auto-convert to `@convention(block)` function types — wrap them explicitly:

```swift
let block: @convention(block) (UnsafePointer<CChar>) -> Void = { pointer in
    userCallback(String(cString: pointer))
}
function(block)
```

---

### Task 6: Wrap `utils_priv.h` (7 functions — smallest, do first)

**Files:**
- Create: `Sources/DyldPrivate/API/MachOUtils.swift`
- Create: `Tests/DyldPrivateTests/MachOUtilsTests.swift`
- Modify: `Sources/DyldPrivate/Obfuscation/ObfuscatedDyldSymbols.swift`
- Modify: `Tests/DyldPrivateTests/Fixtures/ForbiddenSymbolList.swift`

**Function checklist (copy into a TodoWrite list while working — each gets its own wrapper + test + commit):**

| # | C symbol                               | C signature                                                                                                                                                                        |
|---|----------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1 | `macho_dylib_install_name`             | `const char* _Nullable macho_dylib_install_name(const struct mach_header* _Nonnull mh)`                                                                                             |
| 2 | `macho_for_each_dependent_dylib`       | `int macho_for_each_dependent_dylib(const struct mach_header* mh, size_t mappedSize, void (^callback)(const char* loadPath, const char* attributes, bool* stop))`                   |
| 3 | `macho_for_each_imported_symbol`       | `int macho_for_each_imported_symbol(const struct mach_header* mh, size_t mappedSize, void (^callback)(const char* symbolName, const char* libraryPath, bool weakImport, bool* stop))` |
| 4 | `macho_for_each_exported_symbol`       | `int macho_for_each_exported_symbol(const struct mach_header* mh, size_t mappedSize, void (^callback)(const char* symbolName, const char* attributes, bool* stop))`                 |
| 5 | `macho_for_each_defined_rpath`         | `int macho_for_each_defined_rpath(const struct mach_header* mh, size_t mappedSize, void (^callback)(const char* rpath, bool* stop))`                                                |
| 6 | `macho_source_version`                 | `bool macho_source_version(const struct mach_header* mh, uint64_t* version)`                                                                                                        |
| 7 | `macho_for_each_runnable_arch_name`    | `void macho_for_each_runnable_arch_name(void (^callback)(const char* archName, bool* stop))`                                                                                        |

- [ ] **Step 6.1: Extend `ObfuscatedDyldSymbols.swift`**

Add to `Sources/DyldPrivate/Obfuscation/ObfuscatedDyldSymbols.swift` (existing enum content preserved, new block appended):

```swift
enum ObfuscatedMachOUtilsSymbols {
    static #Obfuscate {
        let machoDylibInstallName = "macho_dylib_install_name"
        let machoForEachDependentDylib = "macho_for_each_dependent_dylib"
        let machoForEachImportedSymbol = "macho_for_each_imported_symbol"
        let machoForEachExportedSymbol = "macho_for_each_exported_symbol"
        let machoForEachDefinedRpath = "macho_for_each_defined_rpath"
        let machoSourceVersion = "macho_source_version"
        let machoForEachRunnableArchName = "macho_for_each_runnable_arch_name"
    }
}
```

- [ ] **Step 6.2: Extend `ForbiddenSymbolList.swift`**

Append the 7 symbols to `Tests/DyldPrivateTests/Fixtures/ForbiddenSymbolList.swift`.

- [ ] **Step 6.3: Write the first failing test (pointer-returning function)**

Append to `Tests/DyldPrivateTests/MachOUtilsTests.swift`:

```swift
#if canImport(Darwin)
import Darwin
import Testing
@testable import DyldPrivate

@Test
func installNameResolvesForSelf() {
    // libdyld itself has a well-known install name; use it as a witness.
    let rtldDefault = UnsafeMutableRawPointer(bitPattern: -2)
    guard let handle = dlsym(rtldDefault, "dlsym") else {
        Issue.record("could not acquire a known symbol for this test")
        return
    }
    let image = DyldPriv.imageHeader(containing: UnsafeRawPointer(handle))
    #expect(image != nil)

    guard let image else { return }
    let installName = MachOUtils.installName(
        of: image.assumingMemoryBound(to: mach_header.self)
    )
    #expect(installName != nil)
    #expect(installName?.isEmpty == false)
}
#endif
```

- [ ] **Step 6.4: Run to verify it fails**

Run: `swift test --filter MachOUtilsTests 2>&1 | xcsift`
Expected: FAIL with `cannot find 'MachOUtils' in scope`.

- [ ] **Step 6.5: Create `MachOUtils.swift` with function 1 only**

Create `Sources/DyldPrivate/API/MachOUtils.swift`:

```swift
#if canImport(Darwin)
import Darwin

public enum MachOUtils {
    public typealias InstallNameFunction = @convention(c) (UnsafePointer<mach_header>?) -> UnsafePointer<CChar>?

    private static let installNameFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedMachOUtilsSymbols.$machoDylibInstallName,
        as: InstallNameFunction.self
    )

    public static func installName(of header: UnsafePointer<mach_header>) -> String? {
        guard let function = installNameFunction,
              let pointer = function(header)
        else {
            return nil
        }
        return String(cString: pointer)
    }
}
#endif
```

- [ ] **Step 6.6: Run to verify test now passes**

Run: `swift test --filter MachOUtilsTests/installNameResolvesForSelf 2>&1 | xcsift`
Expected: PASS.

- [ ] **Step 6.7: Audit still green**

Run: `swift test --filter ObfuscationAuditTests 2>&1 | xcsift`
Expected: PASS.

- [ ] **Step 6.8: Commit function 1**

```bash
git add Sources/DyldPrivate/Obfuscation/ObfuscatedDyldSymbols.swift Sources/DyldPrivate/API/MachOUtils.swift Tests/DyldPrivateTests/MachOUtilsTests.swift Tests/DyldPrivateTests/Fixtures/ForbiddenSymbolList.swift
git commit -m "feat(MachOUtils): wrap macho_dylib_install_name via dlsym + #Obfuscate"
```

- [ ] **Step 6.9: Functions 2–7 — block-returning template**

For each remaining function in the checklist, repeat the Step 6.3 → 6.8 loop. Functions 2–5 and 7 take a block parameter; use this template:

```swift
extension MachOUtils {
    public typealias ForEachDependentDylibFunction = @convention(c) (
        UnsafePointer<mach_header>?,
        Int,
        @convention(block) (UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafeMutablePointer<Bool>?) -> Void
    ) -> CInt

    private static let forEachDependentDylibFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedMachOUtilsSymbols.$machoForEachDependentDylib,
        as: ForEachDependentDylibFunction.self
    )

    public static func forEachDependentDylib(
        of header: UnsafePointer<mach_header>,
        mappedSize: Int,
        _ body: @escaping (_ loadPath: String, _ attributes: String, _ stop: inout Bool) -> Void
    ) -> CInt {
        guard let function = forEachDependentDylibFunction else {
            return -1
        }
        let block: @convention(block) (UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafeMutablePointer<Bool>?) -> Void = { loadPath, attributes, stop in
            guard let loadPath, let attributes, let stop else { return }
            var localStop = stop.pointee
            body(String(cString: loadPath), String(cString: attributes), &localStop)
            stop.pointee = localStop
        }
        return function(header, mappedSize, block)
    }
}
```

Functions 3, 4, 5 follow the identical block pattern with different payload tuples (consult the table). Function 6 uses a `uint64_t*` out parameter — wrap the `var version: UInt64 = 0` locally, pass `&version`, return `version` on `true` / `nil` on `false`. Function 7 takes only the block (no header).

- [ ] **Step 6.10: One commit per function**

After wrapping each function, a test proves non-nil resolution, the audit stays green, then `git commit -m "feat(MachOUtils): wrap <function name>"`.

- [ ] **Step 6.11: End-of-task verification**

```bash
swift build 2>&1 | xcsift
swift test 2>&1 | xcsift
```
Expected: both `"status": "success"`. Confirm all 7 functions have tests and commits.

---

### Task 7: Wrap `dyld_process_info.h` (14 functions)

**Files:**
- Create: `Sources/DyldPrivate/API/DyldProcessInfo.swift`
- Create: `Tests/DyldPrivateTests/DyldProcessInfoTests.swift`
- Modify: `Sources/DyldPrivate/Obfuscation/ObfuscatedDyldSymbols.swift`
- Modify: `Tests/DyldPrivateTests/Fixtures/ForbiddenSymbolList.swift`

**Function checklist:**

| # | C symbol                                   | Notes                                                         |
|---|--------------------------------------------|---------------------------------------------------------------|
| 1 | `_dyld_process_info_create`                | `kern_return_t*` out-param — return `Result<DyldProcessInfo, DyldError>` |
| 2 | `_dyld_process_info_release`               | void/void — wrap as method on a `DyldProcessInfoHandle`       |
| 3 | `_dyld_process_info_retain`                | void/void                                                     |
| 4 | `_dyld_process_info_get_state`             | struct out-param — return `dyld_process_state_info`           |
| 5 | `_dyld_process_info_get_cache`             | struct out-param — return `dyld_process_cache_info`           |
| 6 | `_dyld_process_info_get_aot_cache`         | struct out-param — return `dyld_process_aot_cache_info`       |
| 7 | `_dyld_process_info_for_each_image`        | block callback                                                |
| 8 | `_dyld_process_info_for_each_aot_image`    | macOS-only; gate with `#if os(macOS)`                         |
| 9 | `_dyld_process_info_for_each_segment`      | block callback                                                |
|10 | `_dyld_process_info_get_platform`          | returns `dyld_platform_t`                                     |
|11 | `_dyld_process_info_notify`                | `kern_return_t*` out-param + block                            |
|12 | `_dyld_process_info_notify_main`           | block callback                                                |
|13 | `_dyld_process_info_notify_release`        | void/void                                                     |
|14 | `_dyld_process_info_notify_retain`         | void/void                                                     |

- [ ] **Step 7.1: Append new enum block to `ObfuscatedDyldSymbols.swift`**

```swift
enum ObfuscatedDyldProcessInfoSymbols {
    static #Obfuscate {
        let processInfoCreate = "_dyld_process_info_create"
        let processInfoRelease = "_dyld_process_info_release"
        let processInfoRetain = "_dyld_process_info_retain"
        let processInfoGetState = "_dyld_process_info_get_state"
        let processInfoGetCache = "_dyld_process_info_get_cache"
        let processInfoGetAotCache = "_dyld_process_info_get_aot_cache"
        let processInfoForEachImage = "_dyld_process_info_for_each_image"
        let processInfoForEachAotImage = "_dyld_process_info_for_each_aot_image"
        let processInfoForEachSegment = "_dyld_process_info_for_each_segment"
        let processInfoGetPlatform = "_dyld_process_info_get_platform"
        let processInfoNotify = "_dyld_process_info_notify"
        let processInfoNotifyMain = "_dyld_process_info_notify_main"
        let processInfoNotifyRelease = "_dyld_process_info_notify_release"
        let processInfoNotifyRetain = "_dyld_process_info_notify_retain"
    }
}
```

- [ ] **Step 7.2: Append the 14 symbols to `ForbiddenSymbolList.names`**

- [ ] **Step 7.3: Define `DyldError`** (first time — lives in a new file `Sources/DyldPrivate/API/DyldError.swift`)

```swift
#if canImport(Darwin)
import Darwin

public enum DyldError: Error, Sendable {
    case symbolUnavailable(String)
    case mach(kern_return_t)
}
#endif
```

- [ ] **Step 7.4: Follow Pattern (same as Task 6) per function**

For each function: add `@convention(c)` typealias, resolve, expose a Swift wrapper, write a non-nil resolution test, keep the audit green, commit.

For the `kern_return_t*` out-param idiom (functions 1, 11):

```swift
public static func createProcessInfo(task: task_t, timestamp: UInt64) -> Result<DyldProcessInfoHandle, DyldError> {
    guard let function = processInfoCreateFunction else {
        return .failure(.symbolUnavailable("_dyld_process_info_create"))
    }
    var machError: kern_return_t = KERN_SUCCESS
    let rawHandle = withUnsafeMutablePointer(to: &machError) { function(task, timestamp, $0) }
    if machError != KERN_SUCCESS {
        return .failure(.mach(machError))
    }
    guard let rawHandle else {
        return .failure(.symbolUnavailable("_dyld_process_info_create"))
    }
    return .success(.init(rawValue: rawHandle))
}
```

- [ ] **Step 7.5: End-of-task verification + commit (one commit per function, as in Task 6)**

---

### Task 8: Wrap `dyld_introspection.h` (30 functions)

**Files:**
- Create: `Sources/DyldPrivate/API/DyldIntrospection.swift` (if it exceeds ~300 LOC, split by theme: `DyldIntrospection+Process.swift`, `DyldIntrospection+Cache.swift`, `DyldIntrospection+Image.swift`)
- Create: `Tests/DyldPrivateTests/DyldIntrospectionTests.swift`
- Modify: `Sources/DyldPrivate/Obfuscation/ObfuscatedDyldSymbols.swift`
- Modify: `Tests/DyldPrivateTests/Fixtures/ForbiddenSymbolList.swift`

**Function checklist (group by semantic theme for cleaner file split):**

**Process lifecycle (6):**
- `dyld_process_create_for_current_task`
- `dyld_process_create_for_task`
- `dyld_process_dispose`
- `dyld_process_snapshot_create_for_process`
- `dyld_process_snapshot_create_from_data`
- `dyld_process_snapshot_dispose`

**Notifications (3):**
- `dyld_process_register_for_image_notifications`
- `dyld_process_register_for_event_notification`
- `dyld_process_unregister_for_notification`

**Snapshot traversal (2):**
- `dyld_process_snapshot_for_each_image`
- `dyld_process_snapshot_get_shared_cache`

**Shared-cache enumeration (6):**
- `dyld_for_each_installed_shared_cache`
- `dyld_for_each_installed_shared_cache_with_system_path`
- `dyld_shared_cache_for_file`
- `dyld_shared_cache_pin_mapping`
- `dyld_shared_cache_unpin_mapping`
- `dyld_shared_cache_for_each_file`

**Shared-cache properties (5):**
- `dyld_shared_cache_get_base_address`
- `dyld_shared_cache_get_mapped_size`
- `dyld_shared_cache_is_mapped_private`
- `dyld_shared_cache_copy_uuid`
- `dyld_shared_cache_for_each_image`

**Image accessors (8):**
- `dyld_image_copy_uuid`
- `dyld_image_get_installname`
- `dyld_image_get_file_path`
- `dyld_image_for_each_segment_info`
- `dyld_image_content_for_segment`
- `dyld_image_for_each_section_info`
- `dyld_image_content_for_section`
- `dyld_image_local_nlist_content_4Symbolication`

- [ ] **Step 8.1: Create `enum ObfuscatedDyldIntrospectionSymbols` with all 30 `let` entries inside one `#Obfuscate` block**, mirroring the checklist above.

- [ ] **Step 8.2: Append the 30 symbols to `ForbiddenSymbolList.names`.**

- [ ] **Step 8.3: Split creation across 4 files** grouped by the themes above (`+Process.swift`, `+Notifications.swift`, `+Cache.swift`, `+Image.swift`). One theme per commit.

- [ ] **Step 8.4: Apply the standard wrapping pattern (see Phase C preamble) to every function; one commit per function.**

- [ ] **Step 8.5: End-of-task verification.**

```bash
swift build 2>&1 | xcsift
swift test 2>&1 | xcsift
```

Expected: both `"status": "success"`.

---

### Task 9: Wrap `dyld_priv.h` (≈ 83 functions — largest; dispatch in parallel subagents)

**Files:**
- Create (one per theme): `Sources/DyldPrivate/API/DyldPriv+<Theme>.swift`
- Create: `Tests/DyldPrivateTests/DyldPriv<Theme>Tests.swift`
- Modify: `Sources/DyldPrivate/Obfuscation/ObfuscatedDyldSymbols.swift`
- Modify: `Tests/DyldPrivateTests/Fixtures/ForbiddenSymbolList.swift`

**Theme split (each theme is an independent sub-task — good subagent boundary):**

**Theme 1 — atfork/fork (6):**
`_dyld_atfork_prepare`, `_dyld_atfork_parent`, `_dyld_fork_child`, `_dyld_dlopen_atfork_prepare`, `_dyld_dlopen_atfork_parent`, `_dyld_dlopen_atfork_child`.

**Theme 2 — ObjC notify registration (2):**
`_dyld_objc_notify_register`, `_dyld_objc_register_callbacks`.

**Theme 3 — Image info (9):**
`_dyld_lookup_section_info`, `_dyld_get_image_slide`, `_dyld_find_unwind_sections`, `dyld_image_path_containing_address` *(moved from Task 5)*, `dyld_image_header_containing_address` *(moved from Task 5)*, `_dyld_get_prog_image_header`, `_dyld_get_dlopen_image_header`, `_dyld_get_image_uuid`, `_dyld_images_for_addresses`.

**Theme 4 — Platform (5):**
`dyld_get_active_platform`, `dyld_get_base_platform`, `dyld_is_simulator_platform`, `dyld_sdk_at_least`, `dyld_minos_at_least`.

**Theme 5 — Program version (11):**
`dyld_program_sdk_at_least`, `dyld_program_minos_at_least`, `dyld_get_program_sdk_version_token`, `dyld_get_program_minos_version_token`, `dyld_version_token_get_platform`, `dyld_version_token_at_least`, `dyld_get_image_versions`, `dyld_get_sdk_version`, `dyld_get_program_sdk_version`, `dyld_get_program_sdk_watch_os_version`, `dyld_get_program_min_watch_os_version`.

**Theme 6 — Image min-OS version (2):**
`dyld_get_min_os_version`, `dyld_get_program_min_os_version`.

**Theme 7 — Process status (4):**
`dyld_shared_cache_some_image_overridden`, `dyld_process_is_restricted`, `dyld_has_inserted_or_interposing_libraries`, `_dyld_has_fix_for_radar`.

**Theme 8 — Shared cache (10):**
`dyld_shared_cache_file_path` *(already wrapped in Task 5)*, `dyld_shared_cache_iterate_text`, `dyld_shared_cache_find_iterate_text`, `_dyld_is_memory_immutable`, `_dyld_get_shared_cache_uuid`, `_dyld_get_shared_cache_range` *(already wrapped)*, `_dyld_shared_cache_optimized`, `_dyld_shared_cache_is_locally_built`, `_dyld_shared_cache_real_path`, `dyld_need_closure`.

**Theme 9 — Interpose / dynamic (1):**
`dyld_dynamic_interpose`.

**Theme 10 — Registration (3):**
`_dyld_register_for_image_loads`, `_dyld_register_for_bulk_image_loads`, `_dyld_register_driverkit_main`.

**Theme 11 — Runtime launch (1):**
`_dyld_launch_mode`.

**Theme 12 — Symbol-finding internals (documented skip):**
`_dyld_initializer` (dyld calls this, consumers should not), `dyld_stub_binder` (asm entry point — skipped intentionally; document in `DyldPriv+InternalOnly.swift` header comment).

**Globals (documented skip or direct bridge via `DyldPrivateC`):**
`NXArgc`, `NXArgv`, `environ`, `__progname`, `dyldVersionString` — these are *variables*, not functions; expose via `DyldPriv+Globals.swift` using `dlsym` with `assumingMemoryBound`. One commit covers all globals.

- [ ] **Step 9.1: One theme at a time, following the Phase C pattern end-to-end.** Write one `#Obfuscate` block per theme inside a new enum (`ObfuscatedDyldPrivAtforkSymbols`, …) to keep literal lists short and readable. Each function: wrapper + test + audit + commit.

- [ ] **Step 9.2: Theme 3 and Theme 8 append to existing files from Task 5.** Do NOT create new files for them — add the new functions (and per-theme obfuscation enum) into the existing `Sources/DyldPrivate/API/DyldPriv+Image.swift` and `Sources/DyldPrivate/API/DyldPriv+SharedCache.swift`. The already-wrapped symbols (`dyld_image_header_containing_address`, `dyld_image_path_containing_address`, `dyld_shared_cache_file_path`, `_dyld_get_shared_cache_range`) are already on the checklist as done — skip those rows, wrap everything else.

- [ ] **Step 9.3: If dispatching to subagents,** use `superpowers:dispatching-parallel-agents` — themes 1, 4, 5, 6, 7, 11 are independent and safe to run in parallel. Themes 3 and 8 cannot be parallelized with each other if they share the `ObfuscatedDyldSymbols.swift` file edit; serialize the obfuscation-enum update step, then parallelize the per-function wrappers.

- [ ] **Step 9.4: End-of-task verification.**

```bash
swift build 2>&1 | xcsift
swift test 2>&1 | xcsift
```
Expected: both `"status": "success"`, ≥ 83 new test cases total for this task.

---

## Phase D — Release polish

### Task 10: README + sample usage

**Files:**
- Create: `README.md`

- [ ] **Step 10.1: Write README** with: one-paragraph pitch, SPM snippet, minimal usage for `DyldPriv.sharedCacheFilePath()`, link to `ObfuscationAuditTests` explaining the guarantee, link to MachOKit PR #272 as prior art. No emojis.

- [ ] **Step 10.2: Commit**

```bash
git add README.md
git commit -m "docs: add README covering swift-dyld-private layers, usage, and obfuscation guarantee"
```

---

### Task 11: Final audit + tag

- [ ] **Step 11.1: Release build with optimizations**

```bash
swift build -c release 2>&1 | xcsift
```
Expected: `"status": "success"`, zero warnings.

- [ ] **Step 11.2: Run full test suite against release build**

```bash
swift test -c release 2>&1 | xcsift
```
Expected: `"status": "success"`.

- [ ] **Step 11.3: Expand `ObfuscationAuditTests` to also cover release artifacts**

Extend `findBuildDirectory()` to try `.build/arm64-apple-macosx/release/DyldPrivate.build` when the debug path is absent, then rerun the audit against release `.o` files.

- [ ] **Step 11.4: Manual smoke: `strings` + `otool -L`**

```bash
OBJECT_DIRECTORY=.build/arm64-apple-macosx/release/DyldPrivate.build
fd '\.o$' "$OBJECT_DIRECTORY" -t f -x sh -c 'for forbidden in dyld_shared_cache_file_path _dyld_get_shared_cache_range dyld_image_header_containing_address libdyld.dylib /usr/lib/system; do count=$(strings "$0" | rg -c "$forbidden" || echo 0); test "$count" -eq 0 || { echo "LEAK in $0: $forbidden ($count)"; exit 1; }; done'
otool -L "$OBJECT_DIRECTORY/../libDyldPrivate.dylib" 2>/dev/null || echo "(static target — no dylib to inspect; inspect dependent app instead)"
```
Expected: no `LEAK` lines; `otool -L` (when applicable) does **not** list any direct dependency on a dyld private symbol.

- [ ] **Step 11.5: Tag and commit**

```bash
git add -A
git commit -m "chore: full-audit release verification for swift-dyld-private 1.0.0"
git tag -a v1.0.0 -m "swift-dyld-private 1.0.0 — fully obfuscated wrapper over dyld private headers"
```

---

## Execution strategy

**Sequential tasks (Phase A + B):** must run in-session.
**Phase C:** strong candidate for `superpowers:subagent-driven-development` — one task or one theme per subagent; each subagent works off the pattern preamble + its dedicated checklist, producing per-function commits. Main session reviews audit output between subagents.
**Phase D:** sequential, in-session.

## Commit hygiene

- One commit per wrapped function. Message format: `feat(<Namespace>): wrap <c_symbol_name>` (e.g., `feat(DyldPriv): wrap dyld_get_active_platform`).
- Never batch multiple function wrappers into a single commit except for the documented-skip/globals case (Theme 12 in Task 9).
- Before every commit: `swift test --filter <NewTest> 2>&1 | xcsift` AND `swift test --filter ObfuscationAuditTests 2>&1 | xcsift`. Both must be `"status": "success"`.

## Out of scope

- Public-header stability / SemVer guarantees across future dyld ABI changes.
- Wrapping types defined only in `dyld_cache_format.h`, `function-variant-macros.h`, `dyld-interposing.h` — those headers are type/macro-only with no `extern` functions; consumers access them through `DyldPrivateC` directly (re-exported via `Exports.swift`).
- Obfuscating struct member names, type names, or compiler-emitted Swift symbols — the plan obfuscates only the C-symbol-lookup strings.
- Code signing / entitlement requirements for consumers; that is the consumer's responsibility.
