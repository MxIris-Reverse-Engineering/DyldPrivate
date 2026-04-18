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
#endif
