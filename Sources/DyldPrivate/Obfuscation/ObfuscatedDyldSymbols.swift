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

enum ObfuscatedDyldPrivRuntimeSymbols {
    static #Obfuscate {
        let launchMode = "_dyld_launch_mode"
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
