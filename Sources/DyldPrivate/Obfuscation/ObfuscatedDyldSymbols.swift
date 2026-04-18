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

enum ObfuscatedMachOUtilsSymbols {
    static #Obfuscate {
        let machoDylibInstallName = "macho_dylib_install_name"
        let machoForEachDependentDylib = "macho_for_each_dependent_dylib"
        let machoForEachImportedSymbol = "macho_for_each_imported_symbol"
        let machoForEachExportedSymbol = "macho_for_each_exported_symbol"
        let machoForEachDefinedRpath = "macho_for_each_defined_rpath"
        let machoSourceVersion = "macho_source_version"
        let machoForEachRunnableArchName = "macho_for_each_runnable_arch_name"
    }
}

enum ObfuscatedDyldProcessInfoSymbols {
    static #Obfuscate {
        let processInfoCreate = "_dyld_process_info_create"
        let processInfoRelease = "_dyld_process_info_release"
        let processInfoRetain = "_dyld_process_info_retain"
        let processInfoGetState = "_dyld_process_info_get_state"
        let processInfoGetCache = "_dyld_process_info_get_cache"
        let processInfoGetAotCache = "_dyld_process_info_get_aot_cache"
        let processInfoForEachImage = "_dyld_process_info_for_each_image"
        let processInfoForEachAotImage = "_dyld_process_info_for_each_aot_image"
        let processInfoForEachSegment = "_dyld_process_info_for_each_segment"
        let processInfoGetPlatform = "_dyld_process_info_get_platform"
        let processInfoNotify = "_dyld_process_info_notify"
        let processInfoNotifyMain = "_dyld_process_info_notify_main"
        let processInfoNotifyRelease = "_dyld_process_info_notify_release"
        let processInfoNotifyRetain = "_dyld_process_info_notify_retain"
    }
}

enum ObfuscatedDyldPrivGlobalsSymbols {
    static #Obfuscate {
        let nxArgc = "NXArgc"
        let nxArgv = "NXArgv"
        let processEnvironment = "environ"
        let progname = "__progname"
        let dyldBuildVersionString = "dyldVersionString"
    }
}

enum ObfuscatedDyldPrivAtforkSymbols {
    static #Obfuscate {
        let atforkPrepare = "_dyld_atfork_prepare"
        let atforkParent = "_dyld_atfork_parent"
        let forkChild = "_dyld_fork_child"
        let dlopenAtforkPrepare = "_dyld_dlopen_atfork_prepare"
        let dlopenAtforkParent = "_dyld_dlopen_atfork_parent"
        let dlopenAtforkChild = "_dyld_dlopen_atfork_child"
    }
}

enum ObfuscatedDyldPrivPlatformSymbols {
    static #Obfuscate {
        let getActivePlatform = "dyld_get_active_platform"
        let getBasePlatform = "dyld_get_base_platform"
        let isSimulatorPlatform = "dyld_is_simulator_platform"
        let sdkAtLeast = "dyld_sdk_at_least"
        let minosAtLeast = "dyld_minos_at_least"
    }
}

enum ObfuscatedDyldPrivProcessStatusSymbols {
    static #Obfuscate {
        let sharedCacheSomeImageOverridden = "dyld_shared_cache_some_image_overridden"
        let processIsRestricted = "dyld_process_is_restricted"
        let hasInsertedOrInterposingLibraries = "dyld_has_inserted_or_interposing_libraries"
        let hasFixForRadar = "_dyld_has_fix_for_radar"
    }
}

enum ObfuscatedDyldPrivRuntimeSymbols {
    static #Obfuscate {
        let launchMode = "_dyld_launch_mode"
    }
}

enum ObfuscatedDyldPrivImageSymbols {
    static #Obfuscate {
        let lookupSectionInfo = "_dyld_lookup_section_info"
        let getImageSlide = "_dyld_get_image_slide"
        let findUnwindSections = "_dyld_find_unwind_sections"
        let getProgImageHeader = "_dyld_get_prog_image_header"
        let getDlopenImageHeader = "_dyld_get_dlopen_image_header"
        let getImageUUID = "_dyld_get_image_uuid"
        let imagesForAddresses = "_dyld_images_for_addresses"
    }
}

enum ObfuscatedDyldPrivVersionSymbols {
    static #Obfuscate {
        let programSdkAtLeast = "dyld_program_sdk_at_least"
        let programMinosAtLeast = "dyld_program_minos_at_least"
        let getProgramSdkVersionToken = "dyld_get_program_sdk_version_token"
        let getProgramMinosVersionToken = "dyld_get_program_minos_version_token"
        let versionTokenGetPlatform = "dyld_version_token_get_platform"
        let versionTokenAtLeast = "dyld_version_token_at_least"
        let getImageVersions = "dyld_get_image_versions"
        let getSdkVersion = "dyld_get_sdk_version"
        let getProgramSdkVersion = "dyld_get_program_sdk_version"
    }
}

#if os(watchOS)
enum ObfuscatedDyldPrivVersionWatchOSSymbols {
    static #Obfuscate {
        let getProgramSdkWatchOSVersion = "dyld_get_program_sdk_watch_os_version"
        let getProgramMinWatchOSVersion = "dyld_get_program_min_watch_os_version"
    }
}
#endif

enum ObfuscatedDyldPrivSharedCacheSymbols {
    static #Obfuscate {
        let sharedCacheIterateText = "dyld_shared_cache_iterate_text"
        let sharedCacheFindIterateText = "dyld_shared_cache_find_iterate_text"
        let isMemoryImmutable = "_dyld_is_memory_immutable"
        let getSharedCacheUUID = "_dyld_get_shared_cache_uuid"
        let sharedCacheIsOptimized = "_dyld_shared_cache_optimized"
        let sharedCacheIsLocallyBuilt = "_dyld_shared_cache_is_locally_built"
        let sharedCacheRealPath = "_dyld_shared_cache_real_path"
        let needClosure = "dyld_need_closure"
    }
}

enum ObfuscatedDyldPrivObjCNotifySymbols {
    static #Obfuscate {
        let objcNotifyRegister = "_dyld_objc_notify_register"
        let objcRegisterCallbacks = "_dyld_objc_register_callbacks"
    }
}

enum ObfuscatedDyldPrivRegistrationSymbols {
    static #Obfuscate {
        let registerForImageLoads = "_dyld_register_for_image_loads"
        let registerForBulkImageLoads = "_dyld_register_for_bulk_image_loads"
        let registerDriverkitMain = "_dyld_register_driverkit_main"
    }
}

enum ObfuscatedDyldPrivInterposeSymbols {
    static #Obfuscate {
        let dynamicInterpose = "dyld_dynamic_interpose"
    }
}

enum ObfuscatedDyldPrivMinOSVersionSymbols {
    static #Obfuscate {
        let getMinOSVersion = "dyld_get_min_os_version"
        let getProgramMinOSVersion = "dyld_get_program_min_os_version"
    }
}

enum ObfuscatedDyldIntrospectionSymbols {
    static #Obfuscate {
        // Process lifecycle
        let processCreateForCurrentTask = "dyld_process_create_for_current_task"
        let processCreateForTask = "dyld_process_create_for_task"
        let processDispose = "dyld_process_dispose"
        let processSnapshotCreateForProcess = "dyld_process_snapshot_create_for_process"
        let processSnapshotCreateFromData = "dyld_process_snapshot_create_from_data"
        let processSnapshotDispose = "dyld_process_snapshot_dispose"
        let processSnapshotForEachImage = "dyld_process_snapshot_for_each_image"
        let processSnapshotGetSharedCache = "dyld_process_snapshot_get_shared_cache"
        // Notifications
        let processRegisterForImageNotifications = "dyld_process_register_for_image_notifications"
        let processRegisterForEventNotification = "dyld_process_register_for_event_notification"
        let processUnregisterForNotification = "dyld_process_unregister_for_notification"
        // Shared cache enumeration
        let forEachInstalledSharedCache = "dyld_for_each_installed_shared_cache"
        let forEachInstalledSharedCacheWithSystemPath = "dyld_for_each_installed_shared_cache_with_system_path"
        let sharedCacheForFile = "dyld_shared_cache_for_file"
        let sharedCachePinMapping = "dyld_shared_cache_pin_mapping"
        let sharedCacheUnpinMapping = "dyld_shared_cache_unpin_mapping"
        let sharedCacheForEachFile = "dyld_shared_cache_for_each_file"
        // Shared cache properties
        let sharedCacheGetBaseAddress = "dyld_shared_cache_get_base_address"
        let sharedCacheGetMappedSize = "dyld_shared_cache_get_mapped_size"
        let sharedCacheIsMappedPrivate = "dyld_shared_cache_is_mapped_private"
        let sharedCacheCopyUUID = "dyld_shared_cache_copy_uuid"
        let sharedCacheForEachImage = "dyld_shared_cache_for_each_image"
        // Image accessors
        let imageCopyUUID = "dyld_image_copy_uuid"
        let imageGetInstallname = "dyld_image_get_installname"
        let imageGetFilePath = "dyld_image_get_file_path"
        let imageForEachSegmentInfo = "dyld_image_for_each_segment_info"
        let imageContentForSegment = "dyld_image_content_for_segment"
        let imageForEachSectionInfo = "dyld_image_for_each_section_info"
        let imageContentForSection = "dyld_image_content_for_section"
        let imageLocalNlistContent4Symbolication = "dyld_image_local_nlist_content_4Symbolication"
    }
}
#endif
