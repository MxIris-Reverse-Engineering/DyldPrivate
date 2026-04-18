#if canImport(Darwin)
import Darwin

extension DyldPriv {
    public typealias SharedCacheSomeImageOverriddenFunction = @convention(c) () -> Bool

    private static let sharedCacheSomeImageOverriddenFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivProcessStatusSymbols.$sharedCacheSomeImageOverridden,
        as: SharedCacheSomeImageOverriddenFunction.self
    )

    /// Returns whether any image in the dyld shared cache has been overridden
    /// by a file on disk (e.g. via root filesystem injection or cache invalidation).
    public static func sharedCacheSomeImageOverridden() -> Bool? {
        guard let function = sharedCacheSomeImageOverriddenFunction else { return nil }
        return function()
    }
}
#endif
