#if canImport(Darwin)
import Darwin

extension DyldPriv {
    public typealias GetActivePlatformFunction = @convention(c) () -> dyld_platform_t
    public typealias GetBasePlatformFunction = @convention(c) (dyld_platform_t) -> dyld_platform_t
    public typealias IsSimulatorPlatformFunction = @convention(c) (dyld_platform_t) -> Bool
    public typealias SdkAtLeastFunction = @convention(c) (UnsafePointer<mach_header>?, dyld_build_version_t) -> Bool

    private static let getActivePlatformFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivPlatformSymbols.$getActivePlatform,
        as: GetActivePlatformFunction.self
    )

    private static let getBasePlatformFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivPlatformSymbols.$getBasePlatform,
        as: GetBasePlatformFunction.self
    )

    private static let isSimulatorPlatformFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivPlatformSymbols.$isSimulatorPlatform,
        as: IsSimulatorPlatformFunction.self
    )

    private static let sdkAtLeastFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivPlatformSymbols.$sdkAtLeast,
        as: SdkAtLeastFunction.self
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

    /// Returns whether the given platform identifier represents a simulator platform.
    ///
    /// On a physical arm64 Mac running a native macOS process, this returns `false`
    /// for the active platform. On iOS simulator targets it would return `true`.
    public static func isSimulatorPlatform(_ platform: dyld_platform_t) -> Bool? {
        guard let function = isSimulatorPlatformFunction else { return nil }
        return function(platform)
    }

    /// Returns whether the SDK version linked against the given Mach-O image is
    /// at least the version specified in `buildVersion`.
    ///
    /// - Parameters:
    ///   - header: A pointer to a `mach_header` for the image to query.
    ///   - buildVersion: The minimum platform/version pair to test against.
    /// - Returns: `true` if the image's SDK is at or above `buildVersion`, `false` if not,
    ///   or `nil` if the symbol could not be resolved.
    public static func sdkAtLeast(header: UnsafePointer<mach_header>, buildVersion: dyld_build_version_t) -> Bool? {
        guard let function = sdkAtLeastFunction else { return nil }
        return function(header, buildVersion)
    }
}
#endif
