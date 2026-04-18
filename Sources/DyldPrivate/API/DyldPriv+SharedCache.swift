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

    // MARK: - dyld_need_closure

    public typealias NeedClosureFunction = @convention(c) (
        UnsafePointer<CChar>?,
        UnsafePointer<CChar>?
    ) -> Bool

    private static let needClosureFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivSharedCacheSymbols.$needClosure,
        as: NeedClosureFunction.self
    )

    /// Returns whether the given app needs a dyld closure built.
    ///
    /// - Parameters:
    ///   - executablePath: The path to the executable.
    ///   - dataContainerRootDir: The root directory of the app's data container.
    /// - Returns: `true` if a closure needs to be built, `false` if one is already up-to-date,
    ///   or `nil` if the symbol could not be resolved.
    public static func needsClosure(executablePath: String, dataContainerRootDir: String) -> Bool? {
        guard let function = needClosureFunction else { return nil }
        return executablePath.withCString { executablePathPointer in
            dataContainerRootDir.withCString { dataContainerRootDirPointer in
                function(executablePathPointer, dataContainerRootDirPointer)
            }
        }
    }

    // MARK: - _dyld_is_memory_immutable

    public typealias IsMemoryImmutableFunction = @convention(c) (UnsafeRawPointer?, Int) -> Bool

    private static let isMemoryImmutableFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivSharedCacheSymbols.$isMemoryImmutable,
        as: IsMemoryImmutableFunction.self
    )

    /// Returns whether the specified address range is in dyld-owned memory that is
    /// mapped read-only and will never be unloaded.
    ///
    /// - Parameters:
    ///   - pointer: The starting address of the memory range to check.
    ///   - size: The length (in bytes) of the range to check.
    /// - Returns: `true` if the range is immutable dyld memory, `false` otherwise,
    ///   or `nil` if the symbol could not be resolved.
    public static func isMemoryImmutable(pointer: UnsafeRawPointer, size: Int) -> Bool? {
        guard let function = isMemoryImmutableFunction else { return nil }
        return function(pointer, size)
    }

    // MARK: - dyld_shared_cache_iterate_text

    public typealias SharedCacheIterateTextFunction = @convention(c) (
        UnsafePointer<UInt8>?,
        @convention(block) (UnsafePointer<dyld_shared_cache_dylib_text_info>?) -> Void
    ) -> Int32

    private static let sharedCacheIterateTextFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivSharedCacheSymbols.$sharedCacheIterateText,
        as: SharedCacheIterateTextFunction.self
    )

    /// Iterates over all dylibs in the dyld shared cache file matching the given UUID.
    ///
    /// - Parameters:
    ///   - cacheUUID: The UUID of the shared cache to iterate.
    ///   - body: Called for each dylib in the cache with a pointer to its text info.
    /// - Returns: 0 on success, a non-zero error code on failure, or `nil` if the symbol
    ///   could not be resolved.
    @discardableResult
    public static func sharedCacheIterateText(
        uuid cacheUUID: inout uuid_t,
        body: @escaping (UnsafePointer<dyld_shared_cache_dylib_text_info>) -> Void
    ) -> Int32? {
        guard let function = sharedCacheIterateTextFunction else { return nil }
        let block: @convention(block) (UnsafePointer<dyld_shared_cache_dylib_text_info>?) -> Void = { infoPointer in
            guard let infoPointer else { return }
            body(infoPointer)
        }
        return withUnsafeBytes(of: &cacheUUID) { rawBuffer in
            function(rawBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self), block)
        }
    }
}

#endif
