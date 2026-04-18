#if canImport(Darwin)
import Darwin

extension DyldPriv {
    public typealias GetActivePlatformFunction = @convention(c) () -> dyld_platform_t
    public typealias GetBasePlatformFunction = @convention(c) (dyld_platform_t) -> dyld_platform_t

    private static let getActivePlatformFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivPlatformSymbols.$getActivePlatform,
        as: GetActivePlatformFunction.self
    )

    private static let getBasePlatformFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivPlatformSymbols.$getBasePlatform,
        as: GetBasePlatformFunction.self
    )

    /// Returns the active platform identifier for the current process.
    ///
    /// The value is a `dyld_platform_t` (UInt32). On a macOS process this is
    /// typically `PLATFORM_MACOS` (1). A non-zero value is expected on any
    /// Apple platform.
    public static func getActivePlatform() -> dyld_platform_t? {
        guard let function = getActivePlatformFunction else { return nil }
        return function()
    }

    /// Returns the base (non-simulator) platform for a given platform identifier.
    ///
    /// For simulator platforms (e.g. iOS simulator), this returns the corresponding
    /// host platform (e.g. macOS). For non-simulator platforms it returns the input unchanged.
    public static func getBasePlatform(_ platform: dyld_platform_t) -> dyld_platform_t? {
        guard let function = getBasePlatformFunction else { return nil }
        return function(platform)
    }
}
#endif
