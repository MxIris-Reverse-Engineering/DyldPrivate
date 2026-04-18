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

// MARK: - Function 6: _dyld_process_info_get_aot_cache

extension DyldProcessInfo {
    public typealias ProcessInfoGetAotCacheFunction = @convention(c) (
        UnsafeRawPointer?,
        UnsafeMutablePointer<dyld_process_aot_cache_info>?
    ) -> Void

    private static let processInfoGetAotCacheFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldProcessInfoSymbols.$processInfoGetAotCache,
        as: ProcessInfoGetAotCacheFunction.self
    )

    /// Returns AOT cache information for the given handle.
    /// - Parameter handle: A valid `DyldProcessInfoHandle`.
    /// - Returns: A `dyld_process_aot_cache_info` struct, or nil if the symbol could not be resolved.
    public static func aotCacheInfo(of handle: DyldProcessInfoHandle) -> dyld_process_aot_cache_info? {
        guard let function = processInfoGetAotCacheFunction else {
            return nil
        }
        var aotCacheInfo = dyld_process_aot_cache_info()
        function(handle.rawValue, &aotCacheInfo)
        return aotCacheInfo
    }
}

// MARK: - Function 7: _dyld_process_info_for_each_image

extension DyldProcessInfo {
    // Use UnsafeRawPointer for the uuid parameter because uuid_t (a tuple) is not
    // representable in Objective-C and cannot appear directly in @convention(block).
    public typealias ProcessInfoForEachImageFunction = @convention(c) (
        UnsafeRawPointer?,
        @convention(block) (UInt64, UnsafeRawPointer?, UnsafePointer<CChar>?) -> Void
    ) -> Void

    private static let processInfoForEachImageFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldProcessInfoSymbols.$processInfoForEachImage,
        as: ProcessInfoForEachImageFunction.self
    )

    /// Iterates all images loaded in the process represented by the given handle.
    ///
    /// - Parameters:
    ///   - handle: A valid `DyldProcessInfoHandle`.
    ///   - body: Called for each image with its mach header address, UUID, and file path.
    public static func forEachImage(
        in handle: DyldProcessInfoHandle,
        _ body: @escaping (_ machHeaderAddress: UInt64, _ uuid: uuid_t, _ path: String) -> Void
    ) {
        guard let function = processInfoForEachImageFunction else {
            return
        }
        let block: @convention(block) (UInt64, UnsafeRawPointer?, UnsafePointer<CChar>?) -> Void = {
            machHeaderAddress, uuidRawPointer, pathPointer in
            let uuidValue: uuid_t
            if let uuidRawPointer {
                uuidValue = uuidRawPointer.load(as: uuid_t.self)
            } else {
                uuidValue = uuid_t(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
            }
            let pathString = pathPointer.map { String(cString: $0) } ?? ""
            body(machHeaderAddress, uuidValue, pathString)
        }
        function(handle.rawValue, block)
    }
}

// MARK: - Function 8: _dyld_process_info_for_each_aot_image (macOS only)

#if os(macOS)
extension DyldProcessInfo {
    public typealias ProcessInfoForEachAotImageFunction = @convention(c) (
        UnsafeRawPointer?,
        @convention(block) (UInt64, UInt64, UInt64, UnsafeMutablePointer<UInt8>?, Int) -> Bool
    ) -> Void

    private static let processInfoForEachAotImageFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldProcessInfoSymbols.$processInfoForEachAotImage,
        as: ProcessInfoForEachAotImageFunction.self
    )

    /// Iterates all AOT (Ahead-Of-Time) images in the process represented by the given handle.
    /// This API is only available on macOS. On non-AOT processes, the callback may never fire.
    ///
    /// - Parameters:
    ///   - handle: A valid `DyldProcessInfoHandle`.
    ///   - body: Called for each AOT image. Return `false` to stop iteration early.
    public static func forEachAotImage(
        in handle: DyldProcessInfoHandle,
        _ body: @escaping (
            _ x86Address: UInt64,
            _ aotAddress: UInt64,
            _ aotSize: UInt64,
            _ aotImageKey: UnsafeMutablePointer<UInt8>?,
            _ aotImageKeySize: Int
        ) -> Bool
    ) {
        guard let function = processInfoForEachAotImageFunction else {
            return
        }
        let block: @convention(block) (UInt64, UInt64, UInt64, UnsafeMutablePointer<UInt8>?, Int) -> Bool = {
            x86Address, aotAddress, aotSize, aotImageKey, aotImageKeySize in
            body(x86Address, aotAddress, aotSize, aotImageKey, aotImageKeySize)
        }
        function(handle.rawValue, block)
    }
}
#endif

// MARK: - Function 9: _dyld_process_info_for_each_segment

extension DyldProcessInfo {
    public typealias ProcessInfoForEachSegmentFunction = @convention(c) (
        UnsafeRawPointer?,
        UInt64,
        @convention(block) (UInt64, UInt64, UnsafePointer<CChar>?) -> Void
    ) -> Void

    private static let processInfoForEachSegmentFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldProcessInfoSymbols.$processInfoForEachSegment,
        as: ProcessInfoForEachSegmentFunction.self
    )

    /// Iterates all segments in a specific image in the process represented by the given handle.
    ///
    /// - Parameters:
    ///   - handle: A valid `DyldProcessInfoHandle`.
    ///   - machHeaderAddress: The mach header address of the image to inspect (as returned by `forEachImage`).
    ///   - body: Called for each segment with its address, size, and name.
    public static func forEachSegment(
        in handle: DyldProcessInfoHandle,
        machHeaderAddress: UInt64,
        _ body: @escaping (_ segmentAddress: UInt64, _ segmentSize: UInt64, _ segmentName: String) -> Void
    ) {
        guard let function = processInfoForEachSegmentFunction else {
            return
        }
        let block: @convention(block) (UInt64, UInt64, UnsafePointer<CChar>?) -> Void = {
            segmentAddress, segmentSize, segmentNamePointer in
            let segmentName = segmentNamePointer.map { String(cString: $0) } ?? ""
            body(segmentAddress, segmentSize, segmentName)
        }
        function(handle.rawValue, machHeaderAddress, block)
    }
}

// MARK: - Function 10: _dyld_process_info_get_platform

extension DyldProcessInfo {
    public typealias ProcessInfoGetPlatformFunction = @convention(c) (UnsafeRawPointer?) -> dyld_platform_t

    private static let processInfoGetPlatformFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldProcessInfoSymbols.$processInfoGetPlatform,
        as: ProcessInfoGetPlatformFunction.self
    )

    /// Returns the platform of the process represented by the given handle.
    /// Returns 0 if the platform cannot be determined.
    /// - Parameter handle: A valid `DyldProcessInfoHandle`.
    /// - Returns: A `dyld_platform_t` (UInt32), or nil if the symbol could not be resolved.
    public static func platform(of handle: DyldProcessInfoHandle) -> dyld_platform_t? {
        guard let function = processInfoGetPlatformFunction else {
            return nil
        }
        return function(handle.rawValue)
    }
}

// MARK: - Function 11: _dyld_process_info_notify

extension DyldProcessInfo {
    // Use UnsafeRawPointer for the uuid parameter because uuid_t (a tuple) is not
    // representable in Objective-C and cannot appear directly in @convention(block).
    public typealias ProcessInfoNotifyFunction = @convention(c) (
        task_t,
        UnsafeRawPointer?,  // dispatch_queue_t — passed as opaque pointer
        @convention(block) (Bool, UInt64, UInt64, UnsafeRawPointer?, UnsafePointer<CChar>?) -> Void,
        @convention(block) () -> Void,
        UnsafeMutablePointer<kern_return_t>?
    ) -> UnsafeRawPointer?

    private static let processInfoNotifyFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldProcessInfoSymbols.$processInfoNotify,
        as: ProcessInfoNotifyFunction.self
    )

    /// Requests notifications when the image list changes in the target process.
    ///
    /// - Parameters:
    ///   - task: The Mach task port of the target process.
    ///   - queue: The dispatch queue on which to call the notify block (passed as opaque pointer).
    ///   - notify: Called each time an image is loaded or unloaded.
    ///   - notifyExit: Called when the target process exits.
    /// - Returns: A `.success` with a `DyldProcessInfoNotifyHandle`, or `.failure` with a `DyldError`.
    public static func notify(
        task: task_t,
        queue: UnsafeRawPointer,
        notify notifyBlock: @escaping (
            _ unload: Bool,
            _ timestamp: UInt64,
            _ machHeader: UInt64,
            _ uuid: uuid_t,
            _ path: String
        ) -> Void,
        notifyExit notifyExitBlock: @escaping () -> Void
    ) -> Result<DyldProcessInfoNotifyHandle, DyldError> {
        // Use the obfuscated symbol string as the error description so that the
        // raw C symbol name never appears as a literal in the compiled object file.
        let symbolName = ObfuscatedDyldProcessInfoSymbols.$processInfoNotify
        guard let function = processInfoNotifyFunction else {
            return .failure(.symbolUnavailable(symbolName))
        }
        let notifyBlockBridge: @convention(block) (Bool, UInt64, UInt64, UnsafeRawPointer?, UnsafePointer<CChar>?) -> Void = {
            unload, timestamp, machHeader, uuidRawPointer, pathPointer in
            let uuidValue: uuid_t
            if let uuidRawPointer {
                uuidValue = uuidRawPointer.load(as: uuid_t.self)
            } else {
                uuidValue = uuid_t(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
            }
            let pathString = pathPointer.map { String(cString: $0) } ?? ""
            notifyBlock(unload, timestamp, machHeader, uuidValue, pathString)
        }
        let notifyExitBlockBridge: @convention(block) () -> Void = {
            notifyExitBlock()
        }
        var machError: kern_return_t = KERN_SUCCESS
        let rawHandle = withUnsafeMutablePointer(to: &machError) { pointerToError in
            function(task, queue, notifyBlockBridge, notifyExitBlockBridge, pointerToError)
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

// MARK: - Function 12: _dyld_process_info_notify_main

extension DyldProcessInfo {
    public typealias ProcessInfoNotifyMainFunction = @convention(c) (
        UnsafeRawPointer?,
        @convention(block) () -> Void
    ) -> Void

    private static let processInfoNotifyMainFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldProcessInfoSymbols.$processInfoNotifyMain,
        as: ProcessInfoNotifyMainFunction.self
    )

    /// Adds a block to call right before main() is entered in the target process.
    /// Does nothing if the target process is already in main().
    ///
    /// - Parameters:
    ///   - handle: A valid `DyldProcessInfoNotifyHandle`.
    ///   - notifyMain: The block to call before the process enters main().
    public static func notifyMain(
        handle: DyldProcessInfoNotifyHandle,
        _ notifyMain: @escaping () -> Void
    ) {
        guard let function = processInfoNotifyMainFunction else {
            return
        }
        let notifyMainBlock: @convention(block) () -> Void = {
            notifyMain()
        }
        function(handle.rawValue, notifyMainBlock)
    }
}
#endif
