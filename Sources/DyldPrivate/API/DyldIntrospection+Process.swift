#if canImport(Darwin)
import Darwin

// MARK: - DyldProcessHandle

/// A handle to a dyld_process_t obtained from dyld_process_create_for_current_task or
/// dyld_process_create_for_task. The caller is responsible for calling dispose() when done.
public struct DyldProcessHandle: @unchecked Sendable {
    /// The raw opaque pointer to the underlying dyld_process_t.
    public let rawValue: OpaquePointer

    public init(rawValue: OpaquePointer) {
        self.rawValue = rawValue
    }
}

// MARK: - DyldProcessSnapshotHandle

/// A handle to a dyld_process_snapshot_t obtained from dyld_process_snapshot_create_for_process
/// or dyld_process_snapshot_create_from_data. The caller is responsible for calling dispose()
/// when done.
public struct DyldProcessSnapshotHandle: @unchecked Sendable {
    /// The raw opaque pointer to the underlying dyld_process_snapshot_t.
    public let rawValue: OpaquePointer

    public init(rawValue: OpaquePointer) {
        self.rawValue = rawValue
    }
}

// MARK: - DyldIntrospection namespace

/// Swift wrappers for the mach-o/dyld_introspection.h functions.
/// All symbol resolution is performed via obfuscated dlsym lookups so that the raw C symbol
/// strings never appear as literals in the compiled object files.
public enum DyldIntrospection {}

// MARK: - Function 1: dyld_process_create_for_current_task

extension DyldIntrospection {
    public typealias ProcessCreateForCurrentTaskFunction = @convention(c) () -> OpaquePointer?

    private static let processCreateForCurrentTaskFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldIntrospectionSymbols.$processCreateForCurrentTask,
        as: ProcessCreateForCurrentTaskFunction.self
    )

    /// Creates a dyld_process_t for the current process.
    ///
    /// - Returns: A `DyldProcessHandle` wrapping the new process object, or nil if the symbol
    ///   could not be resolved or the call returned NULL.
    public static func createProcessForCurrentTask() -> DyldProcessHandle? {
        guard let function = processCreateForCurrentTaskFunction else {
            return nil
        }
        guard let rawPointer = function() else {
            return nil
        }
        return DyldProcessHandle(rawValue: rawPointer)
    }
}

// MARK: - Function 2: dyld_process_create_for_task

extension DyldIntrospection {
    public typealias ProcessCreateForTaskFunction = @convention(c) (
        mach_port_t,
        UnsafeMutablePointer<kern_return_t>?
    ) -> OpaquePointer?

    private static let processCreateForTaskFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldIntrospectionSymbols.$processCreateForTask,
        as: ProcessCreateForTaskFunction.self
    )

    /// Creates a dyld_process_t for the given Mach task.
    ///
    /// - Parameter task: The task_read_t port of the target process.
    /// - Returns: `.success` with a `DyldProcessHandle`, or `.failure` with a `DyldError`.
    public static func createProcess(
        forTask task: mach_port_t
    ) -> Result<DyldProcessHandle, DyldError> {
        guard let function = processCreateForTaskFunction else {
            return .failure(.symbolUnavailable(ObfuscatedDyldIntrospectionSymbols.$processCreateForTask))
        }
        var machError: kern_return_t = KERN_SUCCESS
        let rawPointer = withUnsafeMutablePointer(to: &machError) { function(task, $0) }
        if machError != KERN_SUCCESS {
            return .failure(.mach(machError))
        }
        guard let rawPointer else {
            return .failure(.symbolUnavailable(ObfuscatedDyldIntrospectionSymbols.$processCreateForTask))
        }
        return .success(DyldProcessHandle(rawValue: rawPointer))
    }
}

// MARK: - Function 3: dyld_process_dispose

extension DyldIntrospection {
    public typealias ProcessDisposeFunction = @convention(c) (OpaquePointer?) -> Void

    fileprivate static let processDisposeFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldIntrospectionSymbols.$processDispose,
        as: ProcessDisposeFunction.self
    )
}

extension DyldProcessHandle {
    /// Disposes of this dyld_process_t, releasing all resources it holds.
    /// After calling this, the handle must not be used again.
    public func dispose() {
        DyldIntrospection.processDisposeFunction?(rawValue)
    }
}

// MARK: - Function 4: dyld_process_snapshot_create_for_process

extension DyldIntrospection {
    public typealias ProcessSnapshotCreateForProcessFunction = @convention(c) (
        OpaquePointer?,
        UnsafeMutablePointer<kern_return_t>?
    ) -> OpaquePointer?

    private static let processSnapshotCreateForProcessFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldIntrospectionSymbols.$processSnapshotCreateForProcess,
        as: ProcessSnapshotCreateForProcessFunction.self
    )

    /// Creates a snapshot of the process that can be used for introspecting loaded libraries.
    ///
    /// - Parameter process: A valid `DyldProcessHandle`.
    /// - Returns: `.success` with a `DyldProcessSnapshotHandle`, or `.failure` with a `DyldError`.
    public static func createSnapshot(
        forProcess process: DyldProcessHandle
    ) -> Result<DyldProcessSnapshotHandle, DyldError> {
        guard let function = processSnapshotCreateForProcessFunction else {
            return .failure(.symbolUnavailable(ObfuscatedDyldIntrospectionSymbols.$processSnapshotCreateForProcess))
        }
        var machError: kern_return_t = KERN_SUCCESS
        let rawPointer = withUnsafeMutablePointer(to: &machError) { function(process.rawValue, $0) }
        if machError != KERN_SUCCESS {
            return .failure(.mach(machError))
        }
        guard let rawPointer else {
            return .failure(.symbolUnavailable(ObfuscatedDyldIntrospectionSymbols.$processSnapshotCreateForProcess))
        }
        return .success(DyldProcessSnapshotHandle(rawValue: rawPointer))
    }
}
#endif
