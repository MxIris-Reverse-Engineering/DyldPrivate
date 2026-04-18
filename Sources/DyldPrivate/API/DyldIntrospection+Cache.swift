#if canImport(Darwin)
import Darwin

// MARK: - DyldSharedCacheHandle

/// A handle to a dyld_shared_cache_t obtained from the dyld introspection API.
/// The handle is valid only for the lifetime of the enclosing block invocation unless the cache
/// has been pinned via pinMapping().
public struct DyldSharedCacheHandle: @unchecked Sendable {
    /// The raw opaque pointer to the underlying dyld_shared_cache_t.
    public let rawValue: OpaquePointer

    public init(rawValue: OpaquePointer) {
        self.rawValue = rawValue
    }
}

// MARK: - Function 12: dyld_for_each_installed_shared_cache

extension DyldIntrospection {
    public typealias ForEachInstalledSharedCacheFunction = @convention(c) (
        @convention(block) (OpaquePointer?) -> Void
    ) -> Void

    private static let forEachInstalledSharedCacheFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldIntrospectionSymbols.$forEachInstalledSharedCache,
        as: ForEachInstalledSharedCacheFunction.self
    )

    /// Iterates over each shared cache provided by the operating system (equivalent to calling
    /// forEachInstalledSharedCache(withSystemPath: "/", …)).
    ///
    /// - Parameter body: Called for each installed shared cache with a `DyldSharedCacheHandle`.
    ///   The handle is valid only for the lifetime of the block.
    public static func forEachInstalledSharedCache(
        _ body: @escaping (_ cache: DyldSharedCacheHandle) -> Void
    ) {
        guard let function = forEachInstalledSharedCacheFunction else {
            return
        }
        let block: @convention(block) (OpaquePointer?) -> Void = { cachePointer in
            guard let cachePointer else { return }
            body(DyldSharedCacheHandle(rawValue: cachePointer))
        }
        function(block)
    }
}

// MARK: - Function 13: dyld_for_each_installed_shared_cache_with_system_path

extension DyldIntrospection {
    public typealias ForEachInstalledSharedCacheWithSystemPathFunction = @convention(c) (
        UnsafePointer<CChar>?,
        @convention(block) (OpaquePointer?) -> Void
    ) -> Void

    private static let forEachInstalledSharedCacheWithSystemPathFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldIntrospectionSymbols.$forEachInstalledSharedCacheWithSystemPath,
        as: ForEachInstalledSharedCacheWithSystemPathFunction.self
    )

    /// Iterates over each shared cache installed at the given root path.
    ///
    /// - Parameters:
    ///   - rootPath: The root path of the system installation (e.g. "/").
    ///   - body: Called for each installed shared cache with a `DyldSharedCacheHandle`.
    ///     The handle is valid only for the lifetime of the block.
    public static func forEachInstalledSharedCache(
        withSystemPath rootPath: String,
        _ body: @escaping (_ cache: DyldSharedCacheHandle) -> Void
    ) {
        guard let function = forEachInstalledSharedCacheWithSystemPathFunction else {
            return
        }
        let block: @convention(block) (OpaquePointer?) -> Void = { cachePointer in
            guard let cachePointer else { return }
            body(DyldSharedCacheHandle(rawValue: cachePointer))
        }
        rootPath.withCString { function($0, block) }
    }
}

// MARK: - Function 14: dyld_shared_cache_for_file

extension DyldIntrospection {
    public typealias SharedCacheForFileFunction = @convention(c) (
        UnsafePointer<CChar>?,
        @convention(block) (OpaquePointer?) -> Void
    ) -> Bool

    private static let sharedCacheForFileFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldIntrospectionSymbols.$sharedCacheForFile,
        as: SharedCacheForFileFunction.self
    )

    /// Maps in the shared cache at the given file path and invokes the block with it.
    ///
    /// - Parameters:
    ///   - filePath: The file system path to the shared cache file.
    ///   - body: Called with a `DyldSharedCacheHandle` if the cache was successfully mapped.
    /// - Returns: `true` if the cache was successfully mapped and the block was called,
    ///   `false` otherwise (including if the symbol could not be resolved).
    @discardableResult
    public static func sharedCache(
        forFile filePath: String,
        _ body: @escaping (_ cache: DyldSharedCacheHandle) -> Void
    ) -> Bool {
        guard let function = sharedCacheForFileFunction else {
            return false
        }
        let block: @convention(block) (OpaquePointer?) -> Void = { cachePointer in
            guard let cachePointer else { return }
            body(DyldSharedCacheHandle(rawValue: cachePointer))
        }
        return filePath.withCString { function($0, block) }
    }
}

// MARK: - Function 15: dyld_shared_cache_pin_mapping

extension DyldIntrospection {
    public typealias SharedCachePinMappingFunction = @convention(c) (OpaquePointer?) -> Bool

    private static let sharedCachePinMappingFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldIntrospectionSymbols.$sharedCachePinMapping,
        as: SharedCachePinMappingFunction.self
    )

    /// Maps the shared cache into a contiguous range of memory so that content pointers remain
    /// valid beyond the lifetime of the enclosing block.
    ///
    /// - Parameter cache: A valid `DyldSharedCacheHandle`.
    /// - Returns: `true` if the cache was successfully pinned, `false` otherwise (including if
    ///   there is not enough contiguous address space or the symbol could not be resolved).
    @discardableResult
    public static func pinMapping(of cache: DyldSharedCacheHandle) -> Bool {
        guard let function = sharedCachePinMappingFunction else {
            return false
        }
        return function(cache.rawValue)
    }
}

// MARK: - Function 16: dyld_shared_cache_unpin_mapping

extension DyldIntrospection {
    public typealias SharedCacheUnpinMappingFunction = @convention(c) (OpaquePointer?) -> Void

    private static let sharedCacheUnpinMappingFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldIntrospectionSymbols.$sharedCacheUnpinMapping,
        as: SharedCacheUnpinMappingFunction.self
    )

    /// Unmaps a previously pinned shared cache from memory.
    /// All pointers to content within the pinned cache become invalid after this call.
    ///
    /// - Parameter cache: A valid `DyldSharedCacheHandle` that was previously pinned.
    public static func unpinMapping(of cache: DyldSharedCacheHandle) {
        sharedCacheUnpinMappingFunction?(cache.rawValue)
    }
}

// MARK: - Function 17: dyld_shared_cache_for_each_file

extension DyldIntrospection {
    public typealias SharedCacheForEachFileFunction = @convention(c) (
        OpaquePointer?,
        @convention(block) (UnsafePointer<CChar>?) -> Void
    ) -> Void

    private static let sharedCacheForEachFileFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldIntrospectionSymbols.$sharedCacheForEachFile,
        as: SharedCacheForEachFileFunction.self
    )

    /// Iterates over every file path that backs the given shared cache.
    ///
    /// - Parameters:
    ///   - cache: A valid `DyldSharedCacheHandle`.
    ///   - body: Called once for each backing file path with a `String`.
    public static func forEachFile(
        in cache: DyldSharedCacheHandle,
        _ body: @escaping (_ filePath: String) -> Void
    ) {
        guard let function = sharedCacheForEachFileFunction else {
            return
        }
        let block: @convention(block) (UnsafePointer<CChar>?) -> Void = { pathPointer in
            guard let pathPointer else { return }
            body(String(cString: pathPointer))
        }
        function(cache.rawValue, block)
    }
}

// MARK: - Function 18: dyld_shared_cache_get_base_address

extension DyldIntrospection {
    public typealias SharedCacheGetBaseAddressFunction = @convention(c) (OpaquePointer?) -> UInt64

    private static let sharedCacheGetBaseAddressFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldIntrospectionSymbols.$sharedCacheGetBaseAddress,
        as: SharedCacheGetBaseAddressFunction.self
    )

    /// Returns the base address of the shared cache.
    ///
    /// - Parameter cache: A valid `DyldSharedCacheHandle`.
    /// - Returns: The base address as a `UInt64`, or nil if the symbol could not be resolved.
    public static func baseAddress(of cache: DyldSharedCacheHandle) -> UInt64? {
        guard let function = sharedCacheGetBaseAddressFunction else {
            return nil
        }
        return function(cache.rawValue)
    }
}
#endif
