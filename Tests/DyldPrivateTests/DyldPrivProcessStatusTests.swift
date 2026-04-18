#if canImport(Darwin)
import Testing
@testable import DyldPrivate

@Test
func sharedCacheSomeImageOverriddenResolves() {
    // Live-invoke: returns Bool, no side effects.
    let result = DyldPriv.sharedCacheSomeImageOverridden()
    #expect(result != nil)
}

@Test
func processIsRestrictedResolves() {
    // Live-invoke: returns Bool, no side effects.
    let result = DyldPriv.processIsRestricted()
    #expect(result != nil)
}

@Test
func hasInsertedOrInterposingLibrariesResolves() {
    // Live-invoke: returns Bool, no side effects.
    let result = DyldPriv.hasInsertedOrInterposingLibraries()
    #expect(result != nil)
}

@Test
func hasFixForRadarResolves() {
    // Live-invoke with a synthetic radar ID; both true and false are valid results.
    let result = DyldPriv.hasFixForRadar("rdar://0")
    #expect(result != nil)
}
#endif
