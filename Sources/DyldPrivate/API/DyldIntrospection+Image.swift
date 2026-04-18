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

// MARK: - Function 25: dyld_image_get_file_path

extension DyldIntrospection {
    public typealias ImageGetFilePathFunction = @convention(c) (OpaquePointer?) -> UnsafePointer<CChar>?

    private static let imageGetFilePathFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldIntrospectionSymbols.$imageGetFilePath,
        as: ImageGetFilePathFunction.self
    )

    /// Returns the file path of the backing Mach-O file for the image.
    ///
    /// - Parameter image: A valid `DyldImageHandle`.
    /// - Returns: The file path as a `String`, or nil if the symbol could not be resolved,
    ///   the file has been deleted, or there is no Mach-O file backing the image.
    public static func filePath(of image: DyldImageHandle) -> String? {
        guard let function = imageGetFilePathFunction else {
            return nil
        }
        guard let cString = function(image.rawValue) else {
            return nil
        }
        return String(cString: cString)
    }
}

// MARK: - Function 26: dyld_image_for_each_segment_info

extension DyldIntrospection {
    public typealias ImageForEachSegmentInfoFunction = @convention(c) (
        OpaquePointer?,
        @convention(block) (UnsafePointer<CChar>?, UInt64, UInt64, Int32) -> Void
    ) -> Bool

    private static let imageForEachSegmentInfoFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldIntrospectionSymbols.$imageForEachSegmentInfo,
        as: ImageForEachSegmentInfoFunction.self
    )

    /// Iterates over all segments in the image.
    ///
    /// - Parameters:
    ///   - image: A valid `DyldImageHandle`.
    ///   - body: Called for each segment with its name, VM address, VM size, and permissions.
    /// - Returns: `true` if iteration succeeded, `false` if the underlying data was unavailable
    ///   or the symbol could not be resolved.
    @discardableResult
    public static func forEachSegmentInfo(
        in image: DyldImageHandle,
        _ body: @escaping (
            _ segmentName: String,
            _ vmAddress: UInt64,
            _ vmSize: UInt64,
            _ permissions: Int32
        ) -> Void
    ) -> Bool {
        guard let function = imageForEachSegmentInfoFunction else {
            return false
        }
        let block: @convention(block) (UnsafePointer<CChar>?, UInt64, UInt64, Int32) -> Void = {
            namePointer, vmAddress, vmSize, permissions in
            let segmentName = namePointer.map { String(cString: $0) } ?? ""
            body(segmentName, vmAddress, vmSize, permissions)
        }
        return function(image.rawValue, block)
    }
}

// MARK: - Function 27: dyld_image_content_for_segment

extension DyldIntrospection {
    public typealias ImageContentForSegmentFunction = @convention(c) (
        OpaquePointer?,
        UnsafePointer<CChar>?,
        @convention(block) (UnsafeRawPointer?, UInt64, UInt64) -> Void
    ) -> Bool

    private static let imageContentForSegmentFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldIntrospectionSymbols.$imageContentForSegment,
        as: ImageContentForSegmentFunction.self
    )

    /// Materializes the on-disk content for a named segment and passes it to the reader block.
    ///
    /// - Parameters:
    ///   - image: A valid `DyldImageHandle`.
    ///   - segmentName: The name of the segment (e.g. "__TEXT").
    ///   - contentReader: Called with a pointer to the content, its VM address, and its VM size.
    ///     The pointer is valid only for the lifetime of the block unless the cache is pinned.
    /// - Returns: `true` if the content was materialized, `false` otherwise.
    @discardableResult
    public static func contentForSegment(
        in image: DyldImageHandle,
        segmentName: String,
        _ contentReader: @escaping (
            _ content: UnsafeRawPointer,
            _ vmAddress: UInt64,
            _ vmSize: UInt64
        ) -> Void
    ) -> Bool {
        guard let function = imageContentForSegmentFunction else {
            return false
        }
        let block: @convention(block) (UnsafeRawPointer?, UInt64, UInt64) -> Void = {
            contentPointer, vmAddress, vmSize in
            guard let contentPointer else { return }
            contentReader(contentPointer, vmAddress, vmSize)
        }
        return segmentName.withCString { function(image.rawValue, $0, block) }
    }
}

// MARK: - Function 28: dyld_image_for_each_section_info

extension DyldIntrospection {
    public typealias ImageForEachSectionInfoFunction = @convention(c) (
        OpaquePointer?,
        @convention(block) (UnsafePointer<CChar>?, UnsafePointer<CChar>?, UInt64, UInt64) -> Void
    ) -> Bool

    private static let imageForEachSectionInfoFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldIntrospectionSymbols.$imageForEachSectionInfo,
        as: ImageForEachSectionInfoFunction.self
    )

    /// Iterates over all sections in the image.
    ///
    /// - Parameters:
    ///   - image: A valid `DyldImageHandle`.
    ///   - body: Called for each section with its segment name, section name, VM address, and
    ///     VM size.
    /// - Returns: `true` if iteration succeeded, `false` if the underlying data was unavailable
    ///   or the symbol could not be resolved.
    @discardableResult
    public static func forEachSectionInfo(
        in image: DyldImageHandle,
        _ body: @escaping (
            _ segmentName: String,
            _ sectionName: String,
            _ vmAddress: UInt64,
            _ vmSize: UInt64
        ) -> Void
    ) -> Bool {
        guard let function = imageForEachSectionInfoFunction else {
            return false
        }
        let block: @convention(block) (UnsafePointer<CChar>?, UnsafePointer<CChar>?, UInt64, UInt64) -> Void = {
            segmentNamePointer, sectionNamePointer, vmAddress, vmSize in
            let segmentName = segmentNamePointer.map { String(cString: $0) } ?? ""
            let sectionName = sectionNamePointer.map { String(cString: $0) } ?? ""
            body(segmentName, sectionName, vmAddress, vmSize)
        }
        return function(image.rawValue, block)
    }
}
#endif
