#if canImport(Darwin)
import Darwin
import Testing
@testable import DyldPrivateRuntime

private func knownSymbolProbe() -> UnsafeRawPointer? {
    let rtldDefault = UnsafeMutableRawPointer(bitPattern: -2)
    guard let pointer = dlsym(rtldDefault, "malloc") else {
        return nil
    }
    return UnsafeRawPointer(pointer)
}

@Test
func sharedCacheFilePathResolves() {
    let path = DyldRuntime.sharedCacheFilePath()
    #expect(path != nil)
    #expect(path?.isEmpty == false)
}

@Test
func sharedCacheRangeResolves() {
    let range = DyldRuntime.sharedCacheRange()
    #expect(range != nil)
    #expect(range?.size ?? 0 > 0)
}

@Test
func imageHeaderContainingAddressResolves() throws {
    let probe = try #require(knownSymbolProbe())
    let header = DyldRuntime.imageHeader(containing: probe)
    #expect(header != nil)
}

@Test
func imagePathContainingAddressResolves() throws {
    let probe = try #require(knownSymbolProbe())
    let path = DyldRuntime.imagePath(containing: probe)
    #expect(path != nil)
    #expect(path?.isEmpty == false)
}
#endif
