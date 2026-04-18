#if canImport(Darwin)
import Darwin
import Dispatch

// MARK: - Function 9: dyld_process_register_for_image_notifications

extension DyldIntrospection {
    // dispatch_queue_t is bridged to DispatchQueue in Swift. For @convention(c), it cannot appear
    // directly, so we pass it through OpaquePointer and reconstruct via Unmanaged.
    public typealias ProcessRegisterForImageNotificationsFunction = @convention(c) (
        OpaquePointer?,                                          // dyld_process_t
        UnsafeMutablePointer<kern_return_t>?,
        OpaquePointer?,                                          // dispatch_queue_t as opaque
        @convention(block) (OpaquePointer?, Bool) -> Void
    ) -> UInt32

    private static let processRegisterForImageNotificationsFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldIntrospectionSymbols.$processRegisterForImageNotifications,
        as: ProcessRegisterForImageNotificationsFunction.self
    )

    /// Registers for notifications when images are loaded or unloaded in the process.
    /// On initial registration the block is called once for each already-loaded image.
    ///
    /// - Parameters:
    ///   - process: A valid `DyldProcessHandle`.
    ///   - queue: The dispatch queue on which to invoke the notification block.
    ///   - notify: Called for each load or unload event. `loaded` is `true` on load, `false` on
    ///     unload. The `DyldImageHandle` is valid only for the lifetime of the block.
    /// - Returns: `.success` with a non-zero registration handle, or `.failure` with a `DyldError`.
    public static func registerForImageNotifications(
        on process: DyldProcessHandle,
        queue: DispatchQueue,
        _ notify: @escaping (_ image: DyldImageHandle, _ loaded: Bool) -> Void
    ) -> Result<UInt32, DyldError> {
        guard let function = processRegisterForImageNotificationsFunction else {
            return .failure(.symbolUnavailable(ObfuscatedDyldIntrospectionSymbols.$processRegisterForImageNotifications))
        }
        var machError: kern_return_t = KERN_SUCCESS
        let block: @convention(block) (OpaquePointer?, Bool) -> Void = { imagePointer, loaded in
            guard let imagePointer else { return }
            notify(DyldImageHandle(rawValue: imagePointer), loaded)
        }
        let queueOpaque = OpaquePointer(Unmanaged.passUnretained(queue).toOpaque())
        let registrationHandle = withUnsafeMutablePointer(to: &machError) {
            function(process.rawValue, $0, queueOpaque, block)
        }
        if machError != KERN_SUCCESS {
            return .failure(.mach(machError))
        }
        if registrationHandle == 0 {
            return .failure(.symbolUnavailable(ObfuscatedDyldIntrospectionSymbols.$processRegisterForImageNotifications))
        }
        return .success(registrationHandle)
    }
}
#endif
