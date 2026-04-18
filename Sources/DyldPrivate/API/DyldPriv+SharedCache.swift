#if canImport(Darwin)
import Darwin

public enum DyldPriv {}

extension DyldPriv {
    public typealias SharedCacheFilePathFunction = @convention(c) () -> UnsafePointer<CChar>?
    public typealias SharedCacheRangeFunction = @convention(c) (UnsafeMutablePointer<Int>?) -> UnsafeRawPointer?

    private static let sharedCacheFilePathFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldSymbols.$sharedCacheFilePath,
        as: SharedCacheFilePathFunction.self
    )

    private static let sharedCacheRangeFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldSymbols.$sharedCacheRange,
        as: SharedCacheRangeFunction.self
    )

    public static func sharedCacheFilePath() -> String? {
        guard let function = sharedCacheFilePathFunction,
              let pointer = function()
        else {
            return nil
        }
        return String(cString: pointer)
    }

    public static func sharedCacheRange() -> (pointer: UnsafeRawPointer, size: Int)? {
        guard let function = sharedCacheRangeFunction else {
            return nil
        }
        var size = 0
        guard let pointer = withUnsafeMutablePointer(to: &size, { function($0) }) else {
            return nil
        }
        return (pointer, size)
    }

    // MARK: - _dyld_get_shared_cache_uuid

    public typealias GetSharedCacheUUIDFunction = @convention(c) (UnsafeMutablePointer<UInt8>?) -> Bool

    private static let getSharedCacheUUIDFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivSharedCacheSymbols.$getSharedCacheUUID,
        as: GetSharedCacheUUIDFunction.self
    )

    /// Retrieves the UUID of the currently active dyld shared cache.
    ///
    /// - Parameter uuidBuffer: On return, filled with the 16-byte UUID of the shared cache.
    /// - Returns: `true` if the UUID was written, `false` if no shared cache is active,
    ///   or `nil` if the symbol could not be resolved.
    @discardableResult
    public static func getSharedCacheUUID(into uuidBuffer: inout uuid_t) -> Bool? {
        guard let function = getSharedCacheUUIDFunction else { return nil }
        return withUnsafeMutableBytes(of: &uuidBuffer) { rawBuffer in
            function(rawBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self))
        }
    }
}

#endif
