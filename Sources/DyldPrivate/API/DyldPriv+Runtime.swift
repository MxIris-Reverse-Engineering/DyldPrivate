#if canImport(Darwin)
import Darwin

extension DyldPriv {
    public typealias LaunchModeFunction = @convention(c) () -> UInt32

    private static let launchModeFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivRuntimeSymbols.$launchMode,
        as: LaunchModeFunction.self
    )

    /// Returns the dyld launch mode flags for the current process.
    ///
    /// The value is a bitmask of internal dyld launch mode flags (e.g. prewarmed,
    /// closure-used, interposition-disabled). Both zero and non-zero values are valid;
    /// accept any `UInt32` returned by the runtime.
    public static func launchMode() -> UInt32? {
        guard let function = launchModeFunction else { return nil }
        return function()
    }
}
#endif
