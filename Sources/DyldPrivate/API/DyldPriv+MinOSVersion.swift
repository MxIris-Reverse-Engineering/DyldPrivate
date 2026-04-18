#if canImport(Darwin)
import Darwin

extension DyldPriv {
    public typealias GetMinOSVersionFunction = @convention(c) (UnsafePointer<mach_header>?) -> UInt32
    public typealias GetProgramMinOSVersionFunction = @convention(c) () -> UInt32

    private static let getMinOSVersionFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivMinOSVersionSymbols.$getMinOSVersion,
        as: GetMinOSVersionFunction.self
    )

    private static let getProgramMinOSVersionFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivMinOSVersionSymbols.$getProgramMinOSVersion,
        as: GetProgramMinOSVersionFunction.self
    )

    /// Returns the minimum OS version a binary was built to run on.
    ///
    /// - Parameter header: A pointer to the `mach_header` of the image to query.
    /// - Returns: A packed version number (major/minor/patch in high/mid/low bytes),
    ///   zero on error or if no min-OS was recorded, or `nil` if the symbol could not be resolved.
    public static func minOSVersion(of header: UnsafePointer<mach_header>) -> UInt32? {
        guard let function = getMinOSVersionFunction else { return nil }
        return function(header)
    }

    /// Returns the minimum OS version the main executable was built to run on.
    ///
    /// - Returns: A packed version number (major/minor/patch in high/mid/low bytes),
    ///   zero on error or if no min-OS was recorded, or `nil` if the symbol could not be resolved.
    public static func programMinOSVersion() -> UInt32? {
        guard let function = getProgramMinOSVersionFunction else { return nil }
        return function()
    }
}
#endif
