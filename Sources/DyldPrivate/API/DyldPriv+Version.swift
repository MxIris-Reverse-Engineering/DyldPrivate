#if canImport(Darwin)
import Darwin

extension DyldPriv {
    // MARK: - Type aliases

    public typealias ProgramSdkAtLeastFunction = @convention(c) (dyld_build_version_t) -> Bool
    public typealias ProgramMinosAtLeastFunction = @convention(c) (dyld_build_version_t) -> Bool
    public typealias GetProgramSdkVersionTokenFunction = @convention(c) () -> UInt64
    public typealias GetProgramMinosVersionTokenFunction = @convention(c) () -> UInt64
    public typealias VersionTokenGetPlatformFunction = @convention(c) (UInt64) -> dyld_platform_t
    public typealias VersionTokenAtLeastFunction = @convention(c) (UInt64, dyld_build_version_t) -> Bool
    public typealias GetImageVersionsFunction = @convention(c) (UnsafePointer<mach_header>?, @convention(block) (dyld_platform_t, UInt32, UInt32) -> Void) -> Void
    public typealias GetSdkVersionFunction = @convention(c) (UnsafePointer<mach_header>?) -> UInt32
    public typealias GetProgramSdkVersionFunction = @convention(c) () -> UInt32

    // MARK: - Resolved function pointers

    private static let programSdkAtLeastFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivVersionSymbols.$programSdkAtLeast,
        as: ProgramSdkAtLeastFunction.self
    )

    private static let programMinosAtLeastFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivVersionSymbols.$programMinosAtLeast,
        as: ProgramMinosAtLeastFunction.self
    )

    private static let getProgramSdkVersionTokenFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivVersionSymbols.$getProgramSdkVersionToken,
        as: GetProgramSdkVersionTokenFunction.self
    )

    private static let getProgramMinosVersionTokenFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivVersionSymbols.$getProgramMinosVersionToken,
        as: GetProgramMinosVersionTokenFunction.self
    )

    private static let versionTokenGetPlatformFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivVersionSymbols.$versionTokenGetPlatform,
        as: VersionTokenGetPlatformFunction.self
    )

    private static let versionTokenAtLeastFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivVersionSymbols.$versionTokenAtLeast,
        as: VersionTokenAtLeastFunction.self
    )

    private static let getImageVersionsFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivVersionSymbols.$getImageVersions,
        as: GetImageVersionsFunction.self
    )

    private static let getSdkVersionFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivVersionSymbols.$getSdkVersion,
        as: GetSdkVersionFunction.self
    )

    private static let getProgramSdkVersionFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivVersionSymbols.$getProgramSdkVersion,
        as: GetProgramSdkVersionFunction.self
    )

    // MARK: - Public wrappers

    /// Returns whether the main executable's SDK version is at least `buildVersion`.
    ///
    /// - Parameter buildVersion: The platform/version pair to compare against.
    /// - Returns: `true` if the program SDK satisfies the requirement, or `nil` if the symbol
    ///   could not be resolved.
    public static func programSdkAtLeast(_ buildVersion: dyld_build_version_t) -> Bool? {
        guard let function = programSdkAtLeastFunction else { return nil }
        return function(buildVersion)
    }

    /// Returns whether the main executable's minos version is at least `buildVersion`.
    ///
    /// - Parameter buildVersion: The platform/version pair to compare against.
    /// - Returns: `true` if the program minos satisfies the requirement, or `nil` if the symbol
    ///   could not be resolved.
    public static func programMinosAtLeast(_ buildVersion: dyld_build_version_t) -> Bool? {
        guard let function = programMinosAtLeastFunction else { return nil }
        return function(buildVersion)
    }

    /// Returns an opaque token encoding the main executable's SDK version.
    ///
    /// The token is intended for inter-process transport to a daemon that performs the actual
    /// comparison. Tokens are not stable across OS releases and must not be persisted.
    ///
    /// - Returns: An opaque `UInt64` token, or `nil` if the symbol could not be resolved.
    public static func programSdkVersionToken() -> UInt64? {
        guard let function = getProgramSdkVersionTokenFunction else { return nil }
        return function()
    }

    /// Returns an opaque token encoding the main executable's minos version.
    ///
    /// - Returns: An opaque `UInt64` token, or `nil` if the symbol could not be resolved.
    public static func programMinosVersionToken() -> UInt64? {
        guard let function = getProgramMinosVersionTokenFunction else { return nil }
        return function()
    }

    /// Returns the platform encoded in a version token previously obtained from dyld.
    ///
    /// - Parameter token: A token obtained from `programSdkVersionToken()` or similar.
    /// - Returns: The `dyld_platform_t` value encoded in the token, or `nil` if the symbol
    ///   could not be resolved.
    public static func platformFromVersionToken(_ token: UInt64) -> dyld_platform_t? {
        guard let function = versionTokenGetPlatformFunction else { return nil }
        return function(token)
    }

    /// Returns whether a version token satisfies the given `buildVersion` requirement.
    ///
    /// - Parameters:
    ///   - token: An opaque version token from dyld.
    ///   - buildVersion: The platform/version pair to compare against.
    /// - Returns: `true` if the token's version is at least `buildVersion`, or `nil` if the symbol
    ///   could not be resolved.
    public static func versionTokenAtLeast(_ token: UInt64, buildVersion: dyld_build_version_t) -> Bool? {
        guard let function = versionTokenAtLeastFunction else { return nil }
        return function(token, buildVersion)
    }

    /// Calls `callback` for every platform version recorded in the given Mach-O image.
    ///
    /// The callback receives the `dyld_platform_t` identifier, the SDK version (packed
    /// `major.minor.patch` as a `UInt32`), and the minimum OS version in the same format.
    ///
    /// - Parameters:
    ///   - header: A pointer to the `mach_header` of the image to query.
    ///   - callback: A closure invoked for each platform/version pair found.
    public static func enumerateImageVersions(
        of header: UnsafePointer<mach_header>,
        callback: @escaping (dyld_platform_t, UInt32, UInt32) -> Void
    ) {
        guard let function = getImageVersionsFunction else { return }
        function(header, callback)
    }

    /// Returns the SDK version that the given Mach-O image was built against.
    ///
    /// On watchOS and bridgeOS, the returned value is the equivalent iOS SDK version number.
    ///
    /// - Parameter header: A pointer to the `mach_header` of the image to query.
    /// - Returns: A packed version number, zero on error, or `nil` if the symbol could not
    ///   be resolved.
    public static func sdkVersion(of header: UnsafePointer<mach_header>) -> UInt32? {
        guard let function = getSdkVersionFunction else { return nil }
        return function(header)
    }

    /// Returns the SDK version that the main executable was built against.
    ///
    /// On watchOS and bridgeOS, the returned value is the equivalent iOS SDK version number.
    ///
    /// - Returns: A packed version number, zero on error, or `nil` if the symbol could not
    ///   be resolved.
    public static func programSdkVersion() -> UInt32? {
        guard let function = getProgramSdkVersionFunction else { return nil }
        return function()
    }

#if os(watchOS)
    public typealias GetProgramSdkWatchOSVersionFunction = @convention(c) () -> UInt32
    public typealias GetProgramMinWatchOSVersionFunction = @convention(c) () -> UInt32

    private static let getProgramSdkWatchOSVersionFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivVersionWatchOSSymbols.$getProgramSdkWatchOSVersion,
        as: GetProgramSdkWatchOSVersionFunction.self
    )

    private static let getProgramMinWatchOSVersionFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivVersionWatchOSSymbols.$getProgramMinWatchOSVersion,
        as: GetProgramMinWatchOSVersionFunction.self
    )

    /// Returns the watchOS-specific SDK version that the main executable was built against.
    ///
    /// Unlike `programSdkVersion()`, this returns the raw watchOS version (e.g. 2.0)
    /// rather than the iOS equivalent.
    ///
    /// - Returns: A packed watchOS version number, zero on error, or `nil` if the symbol
    ///   could not be resolved.
    public static func programSdkWatchOSVersion() -> UInt32? {
        guard let function = getProgramSdkWatchOSVersionFunction else { return nil }
        return function()
    }

    /// Returns the minimum watchOS version the main executable was built to run on.
    ///
    /// Unlike `programMinOSVersion()`, this returns the raw watchOS version (e.g. 2.0)
    /// rather than the iOS equivalent.
    ///
    /// - Returns: A packed watchOS version number, zero on error, or `nil` if the symbol
    ///   could not be resolved.
    public static func programMinWatchOSVersion() -> UInt32? {
        guard let function = getProgramMinWatchOSVersionFunction else { return nil }
        return function()
    }
#endif
}
#endif
