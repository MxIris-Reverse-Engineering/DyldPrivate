#if canImport(Darwin)
import Darwin

public enum DyldRuntime {
    public typealias SharedCacheFilePathFunction = @convention(c) () -> UnsafePointer<CChar>?
    public typealias SharedCacheRangeFunction = @convention(c) (UnsafeMutablePointer<Int>?) -> UnsafeRawPointer?
    public typealias ImageHeaderContainingAddressFunction = @convention(c) (UnsafeRawPointer?) -> UnsafeRawPointer?
    public typealias ImagePathContainingAddressFunction = @convention(c) (UnsafeRawPointer?) -> UnsafePointer<CChar>?

    private static let sharedCacheFilePathFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldSymbols.$sharedCacheFilePath,
        as: SharedCacheFilePathFunction.self
    )

    private static let sharedCacheRangeFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldSymbols.$sharedCacheRange,
        as: SharedCacheRangeFunction.self
    )

    private static let imageHeaderContainingAddressFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldSymbols.$imageHeaderContainingAddress,
        as: ImageHeaderContainingAddressFunction.self
    )

    private static let imagePathContainingAddressFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldSymbols.$imagePathContainingAddress,
        as: ImagePathContainingAddressFunction.self
    )

    public static func sharedCacheFilePath() -> String? {
        guard let function = sharedCacheFilePathFunction,
              let pointer = function()
        else {
            return nil
        }
        return String(cString: pointer)
    }

    public static func sharedCacheRange() -> (pointer: UnsafeRawPointer, size: Int)? {
        guard let function = sharedCacheRangeFunction else {
            return nil
        }
        var size = 0
        guard let pointer = withUnsafeMutablePointer(to: &size, { function($0) }) else {
            return nil
        }
        return (pointer, size)
    }

    public static func imageHeader(containing address: UnsafeRawPointer) -> UnsafeRawPointer? {
        guard let function = imageHeaderContainingAddressFunction else {
            return nil
        }
        return function(address)
    }

    public static func imagePath(containing address: UnsafeRawPointer) -> String? {
        guard let function = imagePathContainingAddressFunction,
              let pointer = function(address)
        else {
            return nil
        }
        return String(cString: pointer)
    }
}
#endif
