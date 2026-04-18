#if canImport(Darwin)
import Darwin

extension DyldPriv {
    public typealias AtforkPrepareFunction = @convention(c) () -> Void
    public typealias AtforkParentFunction = @convention(c) () -> Void
    public typealias ForkChildFunction = @convention(c) () -> Void
    public typealias DlopenAtforkPrepareFunction = @convention(c) () -> Void

    private static let atforkPrepareFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivAtforkSymbols.$atforkPrepare,
        as: AtforkPrepareFunction.self
    )

    private static let atforkParentFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivAtforkSymbols.$atforkParent,
        as: AtforkParentFunction.self
    )

    private static let forkChildFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivAtforkSymbols.$forkChild,
        as: ForkChildFunction.self
    )

    private static let dlopenAtforkPrepareFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldPrivAtforkSymbols.$dlopenAtforkPrepare,
        as: DlopenAtforkPrepareFunction.self
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

    /// Calls the dyld internal atfork-parent handler.
    ///
    /// WARNING: Must be called only from within the parent's `pthread_atfork` parent handler.
    /// See `atforkPrepare()` for safety notes.
    public static func atforkParent() {
        guard let function = atforkParentFunction else { return }
        function()
    }

    /// Calls the dyld internal fork-child handler.
    ///
    /// WARNING: Must be called only from within the child process immediately after `fork()`.
    /// This allows dyld to reinitialise its internal state in the child.
    /// See `atforkPrepare()` for safety notes.
    public static func forkChild() {
        guard let function = forkChildFunction else { return }
        function()
    }

    /// Calls the dyld internal dlopen atfork-prepare handler.
    ///
    /// WARNING: This function serialises dyld's dlopen lock before a `fork()`.
    /// It must only be called from a `pthread_atfork` prepare handler.
    /// See `atforkPrepare()` for general safety notes.
    public static func dlopenAtforkPrepare() {
        guard let function = dlopenAtforkPrepareFunction else { return }
        function()
    }
}
#endif
