#if canImport(Darwin)
enum ForbiddenSymbolList {
    static let names: [String] = [
        "dyld_shared_cache_file_path",
        "_dyld_get_shared_cache_range",
        "dyld_image_header_containing_address",
        "dyld_image_path_containing_address",
        "/usr/lib/system/libdyld.dylib",
        "libdyld.dylib",
        "macho_dylib_install_name",
        "macho_for_each_dependent_dylib",
        "macho_for_each_imported_symbol",
        "macho_for_each_exported_symbol",
        "macho_for_each_defined_rpath",
        "macho_source_version",
        "macho_for_each_runnable_arch_name",
    ]
}
#endif
