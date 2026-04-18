#if canImport(Darwin)
import Darwin

extension DyldPriv {
    public typealias SharedCacheSomeImageOverriddenFunction = @convention(c) () -> Bool
    public typealias ProcessIsRestrictedFunction = @convention(c) () -> Bool
    public typealias HasInsertedOrInterposingLibrariesFunction = @convention(c) () -> Bool
    public typealias HasFixForRadarFunction = @convention(c) (UnsafePointer<CChar>?) -> Bool

    private static let sharedCacheSomeImageOverriddenFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivProcessStatusSymbols.$sharedCacheSomeImageOverridden,
        as: SharedCacheSomeImageOverriddenFunction.self
    )

    private static let processIsRestrictedFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivProcessStatusSymbols.$processIsRestricted,
        as: ProcessIsRestrictedFunction.self
    )

    private static let hasInsertedOrInterposingLibrariesFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivProcessStatusSymbols.$hasInsertedOrInterposingLibraries,
        as: HasInsertedOrInterposingLibrariesFunction.self
    )

    private static let hasFixForRadarFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivProcessStatusSymbols.$hasFixForRadar,
        as: HasFixForRadarFunction.self
    )

    /// Returns whether any image in the dyld shared cache has been overridden
    /// by a file on disk (e.g. via root filesystem injection or cache invalidation).
    public static func sharedCacheSomeImageOverridden() -> Bool? {
        guard let function = sharedCacheSomeImageOverriddenFunction else { return nil }
        return function()
    }

    /// Returns whether the current process is running in a restricted environment
    /// (e.g. setuid, entitlements that disable library injection).
    public static func processIsRestricted() -> Bool? {
        guard let function = processIsRestrictedFunction else { return nil }
        return function()
    }

    /// Returns whether any libraries were injected via `DYLD_INSERT_LIBRARIES`
    /// or interposing is active in the current process.
    public static func hasInsertedOrInterposingLibraries() -> Bool? {
        guard let function = hasInsertedOrInterposingLibrariesFunction else { return nil }
        return function()
    }

    /// Returns whether dyld has a fix applied for the given radar identifier.
    ///
    /// - Parameter radarIdentifier: A radar identifier string such as `"rdar://12345678"`.
    /// - Returns: `true` if dyld contains a fix for the specified radar, `false` if not,
    ///   or `nil` if the symbol could not be resolved.
    public static func hasFixForRadar(_ radarIdentifier: String) -> Bool? {
        guard let function = hasFixForRadarFunction else { return nil }
        return radarIdentifier.withCString { function($0) }
    }
}
#endif
