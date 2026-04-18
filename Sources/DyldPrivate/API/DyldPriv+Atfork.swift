#if canImport(Darwin)
import Darwin

extension DyldPriv {
    public typealias AtforkPrepareFunction = @convention(c) () -> Void

    private static let atforkPrepareFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivAtforkSymbols.$atforkPrepare,
        as: AtforkPrepareFunction.self
    )

    /// Calls the dyld internal atfork-prepare handler.
    ///
    /// WARNING: This function manipulates dyld's internal fork-safety state.
    /// It is intended to be called only from within a registered `pthread_atfork`
    /// prepare handler, and only when dyld instructs you to do so.
    /// Incorrect use may leave dyld in an inconsistent state.
    public static func atforkPrepare() {
        guard let function = atforkPrepareFunction else { return }
        function()
    }
}
#endif
