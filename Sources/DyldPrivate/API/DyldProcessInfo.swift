#if canImport(Darwin)
import Darwin

// MARK: - DyldProcessInfoHandle

/// A non-owning handle to a dyld_process_info object obtained from _dyld_process_info_create.
/// Callers are responsible for calling release() when done.
public struct DyldProcessInfoHandle: @unchecked Sendable {
    /// The raw dyld_process_info pointer (opaque const pointer).
    public let rawValue: UnsafeRawPointer

    init(rawValue: UnsafeRawPointer) {
        self.rawValue = rawValue
    }
}

// MARK: - DyldProcessInfoNotifyHandle

/// A non-owning handle to a dyld_process_info_notify object obtained from _dyld_process_info_notify.
/// Callers are responsible for calling release() when done.
public struct DyldProcessInfoNotifyHandle: @unchecked Sendable {
    /// The raw dyld_process_info_notify pointer (opaque const pointer).
    public let rawValue: UnsafeRawPointer

    init(rawValue: UnsafeRawPointer) {
        self.rawValue = rawValue
    }
}

// MARK: - DyldProcessInfo namespace

/// Swift wrappers for the private mach-o/dyld_process_info.h functions.
/// All symbol resolution is performed via obfuscated dlsym lookups so that
/// the raw C symbol strings never appear as literals in the compiled object files.
public enum DyldProcessInfo {}

// MARK: - Function 1: _dyld_process_info_create

extension DyldProcessInfo {
    public typealias ProcessInfoCreateFunction = @convention(c) (
        task_t,
        UInt64,
        UnsafeMutablePointer<kern_return_t>?
    ) -> UnsafeRawPointer?

    private static let processInfoCreateFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldProcessInfoSymbols.$processInfoCreate,
        as: ProcessInfoCreateFunction.self
    )

    /// Creates a dyld_process_info snapshot for the specified Mach task.
    ///
    /// - Parameters:
    ///   - task: The Mach task port of the target process.
    ///   - timestamp: Pass 0 to always gather full info. Pass a prior timestamp to skip
    ///                if the image list has not changed since then (returns nil on success).
    /// - Returns: A `.success` containing a `DyldProcessInfoHandle`, or `.failure` with a
    ///            `DyldError` if the symbol could not be resolved or the Mach call failed.
    public static func create(
        task: task_t,
        timestamp: UInt64
    ) -> Result<DyldProcessInfoHandle, DyldError> {
        // Use the obfuscated symbol string as the error description so that the
        // raw C symbol name never appears as a literal in the compiled object file.
        let symbolName = ObfuscatedDyldProcessInfoSymbols.$processInfoCreate
        guard let function = processInfoCreateFunction else {
            return .failure(.symbolUnavailable(symbolName))
        }
        var machError: kern_return_t = KERN_SUCCESS
        let rawHandle = withUnsafeMutablePointer(to: &machError) { pointerToError in
            function(task, timestamp, pointerToError)
        }
        if machError != KERN_SUCCESS {
            return .failure(.mach(machError))
        }
        guard let rawHandle else {
            return .failure(.symbolUnavailable(symbolName))
        }
        return .success(.init(rawValue: rawHandle))
    }
}

// MARK: - Function 2: _dyld_process_info_release

extension DyldProcessInfo {
    public typealias ProcessInfoReleaseFunction = @convention(c) (UnsafeRawPointer?) -> Void

    fileprivate static let processInfoReleaseFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldProcessInfoSymbols.$processInfoRelease,
        as: ProcessInfoReleaseFunction.self
    )
}

extension DyldProcessInfoHandle {
    /// Releases this dyld_process_info handle.
    /// After calling this, the handle must not be used again.
    public func release() {
        DyldProcessInfo.processInfoReleaseFunction?(rawValue)
    }
}

// MARK: - Function 3: _dyld_process_info_retain

extension DyldProcessInfo {
    public typealias ProcessInfoRetainFunction = @convention(c) (UnsafeRawPointer?) -> Void

    fileprivate static let processInfoRetainFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldProcessInfoSymbols.$processInfoRetain,
        as: ProcessInfoRetainFunction.self
    )
}

extension DyldProcessInfoHandle {
    /// Retains this dyld_process_info handle, incrementing its reference count.
    public func retain() {
        DyldProcessInfo.processInfoRetainFunction?(rawValue)
    }
}

// MARK: - Function 4: _dyld_process_info_get_state

extension DyldProcessInfo {
    public typealias ProcessInfoGetStateFunction = @convention(c) (
        UnsafeRawPointer?,
        UnsafeMutablePointer<dyld_process_state_info>?
    ) -> Void

    private static let processInfoGetStateFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldProcessInfoSymbols.$processInfoGetState,
        as: ProcessInfoGetStateFunction.self
    )

    /// Returns process state information for the given handle.
    /// - Parameter handle: A valid `DyldProcessInfoHandle`.
    /// - Returns: A `dyld_process_state_info` struct, or nil if the symbol could not be resolved.
    public static func state(of handle: DyldProcessInfoHandle) -> dyld_process_state_info? {
        guard let function = processInfoGetStateFunction else {
            return nil
        }
        var stateInfo = dyld_process_state_info()
        function(handle.rawValue, &stateInfo)
        return stateInfo
    }
}

// MARK: - Function 5: _dyld_process_info_get_cache

extension DyldProcessInfo {
    public typealias ProcessInfoGetCacheFunction = @convention(c) (
        UnsafeRawPointer?,
        UnsafeMutablePointer<dyld_process_cache_info>?
    ) -> Void

    private static let processInfoGetCacheFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldProcessInfoSymbols.$processInfoGetCache,
        as: ProcessInfoGetCacheFunction.self
    )

    /// Returns dyld shared cache information for the given handle.
    /// - Parameter handle: A valid `DyldProcessInfoHandle`.
    /// - Returns: A `dyld_process_cache_info` struct, or nil if the symbol could not be resolved.
    public static func cacheInfo(of handle: DyldProcessInfoHandle) -> dyld_process_cache_info? {
        guard let function = processInfoGetCacheFunction else {
            return nil
        }
        var cacheInfo = dyld_process_cache_info()
        function(handle.rawValue, &cacheInfo)
        return cacheInfo
    }
}
#endif
