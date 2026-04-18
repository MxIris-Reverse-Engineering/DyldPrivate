#if canImport(Darwin)
import ConfidentialKit

enum ObfuscatedDyldSymbols {
    static #Obfuscate {
        let sharedCacheFilePath = "dyld_shared_cache_file_path"
        let sharedCacheRange = "_dyld_get_shared_cache_range"
        let imageHeaderContainingAddress = "dyld_image_header_containing_address"
        let imagePathContainingAddress = "dyld_image_path_containing_address"
        let libdyldPath = "/usr/lib/system/libdyld.dylib"
    }
}
#endif
