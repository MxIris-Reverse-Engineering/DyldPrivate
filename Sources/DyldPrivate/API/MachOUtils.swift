#if canImport(Darwin)
import Darwin

// MARK: - MachOUtils namespace

/// Swift wrappers for the private mach-o/utils_priv.h functions.
/// All symbol resolution is performed via obfuscated dlsym lookups so that
/// the raw C symbol strings never appear as literals in the compiled object files.
public enum MachOUtils {}

// MARK: - Function 1: macho_dylib_install_name

extension MachOUtils {
    public typealias InstallNameFunction = @convention(c) (UnsafePointer<mach_header>?) -> UnsafePointer<CChar>?

    private static let installNameFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedMachOUtilsSymbols.$machoDylibInstallName,
        as: InstallNameFunction.self
    )

    /// Returns the install name of a dylib image, or nil if the image has no install name
    /// or the underlying function could not be resolved.
    public static func installName(of header: UnsafePointer<mach_header>) -> String? {
        guard let function = installNameFunction,
              let pointer = function(header)
        else {
            return nil
        }
        return String(cString: pointer)
    }
}
#endif
