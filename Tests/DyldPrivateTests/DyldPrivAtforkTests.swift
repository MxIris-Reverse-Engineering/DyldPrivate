#if canImport(Darwin)
import Darwin
import Testing
@testable import DyldPrivate

@Test
func atforkPrepareResolves() {
    // Resolution-only: do NOT invoke — this function manipulates fork state.
    let probeFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivAtforkSymbols.$atforkPrepare,
        as: DyldPriv.AtforkPrepareFunction.self
    )
    #expect(probeFunction != nil)
}

@Test
func atforkParentResolves() {
    // Resolution-only: do NOT invoke — this function manipulates fork state.
    let probeFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivAtforkSymbols.$atforkParent,
        as: DyldPriv.AtforkParentFunction.self
    )
    #expect(probeFunction != nil)
}
#endif
