#if canImport(Darwin)
import Testing
@testable import DyldPrivate

@Test
func sharedCacheSomeImageOverriddenResolves() {
    // Live-invoke: returns Bool, no side effects.
    let result = DyldPriv.sharedCacheSomeImageOverridden()
    #expect(result != nil)
}
#endif
