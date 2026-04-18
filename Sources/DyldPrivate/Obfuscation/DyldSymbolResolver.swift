#if canImport(Darwin)
import Darwin

enum DyldSymbolResolver {
    private struct SendableHandle: @unchecked Sendable {
        let rawValue: UnsafeMutableRawPointer?
    }

    private static let defaultHandle = SendableHandle(
        rawValue: UnsafeMutableRawPointer(bitPattern: -2)
    )

    private enum FallbackHandleHolder {
        static let handle = SendableHandle(
            rawValue: ObfuscatedDyldSymbols.$libdyldPath.withCString {
                dlopen($0, RTLD_LAZY | RTLD_LOCAL)
            }
        )
    }

    static func resolve<FunctionType>(
        symbol name: String,
        as type: FunctionType.Type
    ) -> FunctionType? {
        if let pointer = lookup(symbol: name, handle: defaultHandle.rawValue) {
            return unsafeBitCast(pointer, to: FunctionType.self)
        }
        guard let fallback = FallbackHandleHolder.handle.rawValue,
              let pointer = lookup(symbol: name, handle: fallback)
        else {
            return nil
        }
        return unsafeBitCast(pointer, to: FunctionType.self)
    }

    /// Resolves a data symbol (global variable) by name and returns a typed pointer to its storage.
    /// Unlike `resolve(symbol:as:)` which bitcasts the dlsym result to a function type,
    /// this helper binds the raw pointer returned by dlsym directly to `T` — appropriate
    /// when the symbol IS the variable (e.g. `NXArgc`, `dyldVersionString`).
    static func resolveData<DataType>(
        symbol name: String,
        as type: DataType.Type
    ) -> UnsafePointer<DataType>? {
        if let rawPointer = lookup(symbol: name, handle: defaultHandle.rawValue) {
            return UnsafePointer(rawPointer.assumingMemoryBound(to: DataType.self))
        }
        guard let fallbackHandle = FallbackHandleHolder.handle.rawValue,
              let rawPointer = lookup(symbol: name, handle: fallbackHandle)
        else {
            return nil
        }
        return UnsafePointer(rawPointer.assumingMemoryBound(to: DataType.self))
    }

    private static func lookup(
        symbol name: String,
        handle: UnsafeMutableRawPointer?
    ) -> UnsafeMutableRawPointer? {
        name.withCString { dlsym(handle, $0) }
    }
}
#endif
