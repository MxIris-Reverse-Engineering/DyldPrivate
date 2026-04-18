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
func minOSVersionOfKnownImageResolves() {
    guard let machHeader = knownImageHeader() else {
        Issue.record("could not obtain mach_header for testing")
        return
    }
    let versionValue = DyldPriv.minOSVersion(of: machHeader)
    #expect(versionValue != nil)
    // A well-known system dylib should have a nonzero min-OS version recorded.
    if let versionValue {
        #expect(versionValue > 0)
    }
}

@Test
func programMinOSVersionResolves() {
    let versionValue = DyldPriv.programMinOSVersion()
    #expect(versionValue != nil)
    // The main executable should have a nonzero min-OS version.
    if let versionValue {
        #expect(versionValue > 0)
    }
}
#endif
