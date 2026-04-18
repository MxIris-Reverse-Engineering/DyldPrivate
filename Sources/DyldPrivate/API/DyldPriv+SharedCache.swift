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

    // MARK: - _dyld_shared_cache_optimized

    public typealias SharedCacheIsOptimizedFunction = @convention(c) () -> Bool

    private static let sharedCacheIsOptimizedFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivSharedCacheSymbols.$sharedCacheIsOptimized,
        as: SharedCacheIsOptimizedFunction.self
    )

    /// Returns whether the active dyld shared cache was built with optimizations.
    ///
    /// - Returns: `true` if the shared cache is optimized, `false` if not,
    ///   or `nil` if the symbol could not be resolved.
    public static func sharedCacheIsOptimized() -> Bool? {
        guard let function = sharedCacheIsOptimizedFunction else { return nil }
        return function()
    }

    // MARK: - _dyld_shared_cache_is_locally_built

    public typealias SharedCacheIsLocallyBuiltFunction = @convention(c) () -> Bool

    private static let sharedCacheIsLocallyBuiltFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivSharedCacheSymbols.$sharedCacheIsLocallyBuilt,
        as: SharedCacheIsLocallyBuiltFunction.self
    )

    /// Returns whether the currently active dyld shared cache was built locally.
    ///
    /// - Returns: `true` if the shared cache was built on this machine, `false` if it
    ///   was installed (from Apple), or `nil` if the symbol could not be resolved.
    public static func sharedCacheIsLocallyBuilt() -> Bool? {
        guard let function = sharedCacheIsLocallyBuiltFunction else { return nil }
        return function()
    }

    // MARK: - _dyld_shared_cache_real_path

    public typealias SharedCacheRealPathFunction = @convention(c) (UnsafePointer<CChar>?) -> UnsafePointer<CChar>?

    private static let sharedCacheRealPathFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivSharedCacheSymbols.$sharedCacheRealPath,
        as: SharedCacheRealPathFunction.self
    )

    /// Returns the canonical shared cache path for the given path.
    ///
    /// Similar to `_dyld_shared_cache_contains_path`, but instead of returning a bool,
    /// returns the canonical (real) path for a given path if it is in the shared cache.
    ///
    /// - Parameter path: The path to look up in the shared cache.
    /// - Returns: The canonical path string, `nil` if the path is not in the shared cache,
    ///   or `nil` if the symbol could not be resolved.
    public static func sharedCacheRealPath(for path: String) -> String? {
        guard let function = sharedCacheRealPathFunction else { return nil }
        return path.withCString { pathPointer in
            guard let result = function(pathPointer) else { return nil }
            return String(cString: result)
        }
    }
}

#endif
