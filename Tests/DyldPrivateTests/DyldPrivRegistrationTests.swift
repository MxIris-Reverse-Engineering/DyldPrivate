#if canImport(Darwin)
import Testing
@testable import DyldPrivate

@Test
func dyldRegisterForImageLoadsResolves() {
    // Resolution-only: calling this registers a persistent callback for the process lifetime.
    let probe = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivRegistrationSymbols.$registerForImageLoads,
        as: DyldPriv.RegisterForImageLoadsFunction.self
    )
    #expect(probe != nil)
}


@Test
func dyldRegisterForBulkImageLoadsResolves() {
    // Resolution-only: calling this registers a persistent callback for the process lifetime.
    let probe = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivRegistrationSymbols.$registerForBulkImageLoads,
        as: DyldPriv.RegisterForBulkImageLoadsFunction.self
    )
    #expect(probe != nil)
}

#endif
