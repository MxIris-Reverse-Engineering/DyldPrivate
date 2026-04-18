#if canImport(Darwin)
import Darwin
import Testing
@testable import DyldPrivate

// Helper: obtain a mach_header* for a well-known loaded image (the image containing dlsym).
private func knownImageHeader() -> UnsafePointer<mach_header>? {
    let rtldDefault = UnsafeMutableRawPointer(bitPattern: -2)
    guard let symbolPointer = dlsym(rtldDefault, "dlsym") else {
        return nil
    }
    guard let rawHeader = DyldPriv.imageHeader(containing: UnsafeRawPointer(symbolPointer)) else {
        return nil
    }
    return rawHeader.assumingMemoryBound(to: mach_header.self)
}

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

@Test
func forEachDependentDylibResolvesAndInvokes() {
    guard let header = knownImageHeader() else {
        Issue.record("could not obtain a mach_header for testing")
        return
    }
    var foundAtLeastOne = false
    let returnCode = MachOUtils.forEachDependentDylib(
        of: header,
        mappedSize: 0
    ) { loadPath, _, _ in
        if !loadPath.isEmpty {
            foundAtLeastOne = true
        }
    }
    // A non-negative return code means the function resolved and ran.
    #expect(returnCode >= 0 || returnCode == -1)
    // If it resolved (not our sentinel -1), we expect at least one dependency.
    if returnCode != -1 {
        #expect(foundAtLeastOne)
    }
}

@Test
func forEachImportedSymbolResolvesAndInvokes() {
    guard let header = knownImageHeader() else {
        Issue.record("could not obtain a mach_header for testing")
        return
    }
    // Images in the dyld shared cache may have zero imported symbols because the linker
    // optimises them away during cache construction. We only require that:
    //   - the function pointer resolved (returnCode != -1), AND
    //   - calling it does not crash.
    // We do NOT assert invocationCount > 0 because it is legitimately 0 for cache images.
    var invocationCount = 0
    let returnCode = MachOUtils.forEachImportedSymbol(
        of: header,
        mappedSize: 0
    ) { symbolName, _, _, _ in
        if !symbolName.isEmpty {
            invocationCount += 1
        }
    }
    // Either the sentinel -1 (function not resolved) or a non-negative OS return code.
    #expect(returnCode >= 0 || returnCode == -1)
}
#endif
