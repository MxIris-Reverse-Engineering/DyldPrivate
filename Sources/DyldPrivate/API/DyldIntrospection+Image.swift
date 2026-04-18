#if canImport(Darwin)
import Darwin

// MARK: - DyldImageHandle

/// A handle to a dyld_image_t passed as a block parameter from the dyld introspection API.
/// The handle is only valid for the lifetime of the block invocation unless the backing shared
/// cache is pinned via pinMapping().
public struct DyldImageHandle: @unchecked Sendable {
    /// The raw opaque pointer to the underlying dyld_image_t.
    public let rawValue: OpaquePointer

    public init(rawValue: OpaquePointer) {
        self.rawValue = rawValue
    }
}

// MARK: - Function 23: dyld_image_copy_uuid

extension DyldIntrospection {
    // uuid_t is a Swift tuple, which is not Objective-C representable and cannot appear directly
    // in @convention(c) function pointer types. The C function takes a uuid_t* which is a pointer
    // to 16 bytes, so we use UnsafeMutablePointer<UInt8> (same layout, passes as 16-byte buffer).
    public typealias ImageCopyUUIDFunction = @convention(c) (
        OpaquePointer?,
        UnsafeMutablePointer<UInt8>?
    ) -> Bool

    private static let imageCopyUUIDFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldIntrospectionSymbols.$imageCopyUUID,
        as: ImageCopyUUIDFunction.self
    )

    /// Copies the UUID of the image into a buffer.
    ///
    /// - Parameter image: A valid `DyldImageHandle`.
    /// - Returns: The `uuid_t` if the image has a UUID and the symbol resolved, or nil otherwise.
    public static func copyUUID(of image: DyldImageHandle) -> uuid_t? {
        guard let function = imageCopyUUIDFunction else {
            return nil
        }
        var uuidBuffer = uuid_t(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        let succeeded = withUnsafeMutablePointer(to: &uuidBuffer) { uuidPointer in
            uuidPointer.withMemoryRebound(to: UInt8.self, capacity: 16) { bytePointer in
                function(image.rawValue, bytePointer)
            }
        }
        return succeeded ? uuidBuffer : nil
    }
}

// MARK: - Function 24: dyld_image_get_installname

extension DyldIntrospection {
    public typealias ImageGetInstallnameFunction = @convention(c) (OpaquePointer?) -> UnsafePointer<CChar>?

    private static let imageGetInstallnameFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldIntrospectionSymbols.$imageGetInstallname,
        as: ImageGetInstallnameFunction.self
    )

    /// Returns the install name of the image.
    ///
    /// - Parameter image: A valid `DyldImageHandle`.
    /// - Returns: The install name as a `String`, or nil if the symbol could not be resolved,
    ///   the buffer is unavailable, or the image has no install name.
    public static func installName(of image: DyldImageHandle) -> String? {
        guard let function = imageGetInstallnameFunction else {
            return nil
        }
        guard let cString = function(image.rawValue) else {
            return nil
        }
        return String(cString: cString)
    }
}
#endif
