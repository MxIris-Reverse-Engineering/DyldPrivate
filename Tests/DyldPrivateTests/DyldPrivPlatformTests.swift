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
func getActivePlatformResolves() {
    // Live-invoke: returns the current platform value, no side effects.
    let platformValue = DyldPriv.getActivePlatform()
    #expect(platformValue != nil)
    // On any Apple Darwin platform the value should be non-zero.
    if let platformValue {
        #expect(platformValue > 0)
    }
}

@Test
func getBasePlatformResolves() {
    // Live-invoke: pass active platform; result should be non-zero on any Apple platform.
    guard let activePlatform = DyldPriv.getActivePlatform() else {
        Issue.record("could not obtain active platform for testing")
        return
    }
    let basePlatformValue = DyldPriv.getBasePlatform(activePlatform)
    #expect(basePlatformValue != nil)
    if let basePlatformValue {
        #expect(basePlatformValue > 0)
    }
}
#endif
