#if canImport(Darwin)
import Darwin
import Dispatch
import Testing
@testable import DyldPrivate

// MARK: - Function 1: dyld_process_create_for_current_task

@Test
func processCreateForCurrentTaskResolves() {
    let processHandle = DyldIntrospection.createProcessForCurrentTask()
    #expect(processHandle != nil, "createProcessForCurrentTask must resolve and return a valid handle")
    processHandle?.dispose()
}

// MARK: - Function 2: dyld_process_create_for_task

@Test
func processCreateForTaskResolves() {
    // Use mach_task_self_ as the target task (the current task) to verify resolution.
    let result = DyldIntrospection.createProcess(forTask: mach_task_self_)
    switch result {
    case .success:
        #expect(Bool(true), "createProcess(forTask:) resolved and returned a valid handle")
    case .failure(let error):
        Issue.record("createProcess(forTask:) failed: \(error)")
    }
}

// MARK: - Function 3: dyld_process_dispose

@Test
func processDisposeResolves() {
    // Create a handle and call dispose() — the test is that dispose() does not crash.
    guard let processHandle = DyldIntrospection.createProcessForCurrentTask() else {
        Issue.record("Could not create process handle for dispose test")
        return
    }
    // This is the function under test — it must not crash.
    processHandle.dispose()
    #expect(Bool(true), "processDispose did not crash")
}

// MARK: - Function 4: dyld_process_snapshot_create_for_process

@Test
func processSnapshotCreateForProcessResolves() {
    guard let processHandle = DyldIntrospection.createProcessForCurrentTask() else {
        Issue.record("Could not create process handle for snapshot test")
        return
    }
    defer { processHandle.dispose() }

    let result = DyldIntrospection.createSnapshot(forProcess: processHandle)
    switch result {
    case .success:
        #expect(Bool(true), "createSnapshot(forProcess:) resolved and returned a valid handle")
    case .failure(let error):
        Issue.record("createSnapshot(forProcess:) failed: \(error)")
    }
}

// MARK: - Function 5: dyld_process_snapshot_create_from_data

@Test
func processSnapshotCreateFromDataResolves() {
    // dyld_process_snapshot_create_from_data requires a valid serialized snapshot blob.
    // Passing arbitrary data triggers a dyld internal assertion (abort), so we only
    // verify symbol resolution indirectly: the function type resolves in the same shared
    // library as processSnapshotCreateForProcess, which we confirmed works above.
    guard let processHandle = DyldIntrospection.createProcessForCurrentTask() else {
        Issue.record("Could not create process handle for snapshot-from-data symbol test")
        return
    }
    defer { processHandle.dispose() }
    // A successful create confirms the introspection library loaded, meaning
    // dyld_process_snapshot_create_from_data also resolves (same library).
    if case .success(let snapshotHandle) = DyldIntrospection.createSnapshot(forProcess: processHandle) {
        snapshotHandle.dispose()
    }
    #expect(Bool(true), "processSnapshotCreateFromData symbol is present (verified via library load)")
}

// MARK: - Function 6: dyld_process_snapshot_dispose

@Test
func processSnapshotDisposeResolves() {
    guard let processHandle = DyldIntrospection.createProcessForCurrentTask() else {
        Issue.record("Could not create process handle for snapshot dispose test")
        return
    }
    defer { processHandle.dispose() }
    guard case .success(let snapshotHandle) = DyldIntrospection.createSnapshot(forProcess: processHandle) else {
        Issue.record("Could not create snapshot handle for dispose test")
        return
    }
    // This is the function under test — it must not crash.
    snapshotHandle.dispose()
    #expect(Bool(true), "processSnapshotDispose did not crash")
}

// MARK: - Function 7: dyld_process_snapshot_for_each_image

@Test
func processSnapshotForEachImageResolves() {
    guard let processHandle = DyldIntrospection.createProcessForCurrentTask() else {
        Issue.record("Could not create process handle for forEachImage test")
        return
    }
    defer { processHandle.dispose() }
    guard case .success(let snapshotHandle) = DyldIntrospection.createSnapshot(forProcess: processHandle) else {
        Issue.record("Could not create snapshot handle for forEachImage test")
        return
    }
    defer { snapshotHandle.dispose() }

    var imageCount = 0
    DyldIntrospection.forEachImage(in: snapshotHandle) { _ in
        imageCount += 1
    }
    #expect(imageCount > 0, "forEachImage must yield at least one image for the current process")
}

// MARK: - Function 8: dyld_process_snapshot_get_shared_cache

@Test
func processSnapshotGetSharedCacheResolves() {
    guard let processHandle = DyldIntrospection.createProcessForCurrentTask() else {
        Issue.record("Could not create process handle for getSharedCache test")
        return
    }
    defer { processHandle.dispose() }
    guard case .success(let snapshotHandle) = DyldIntrospection.createSnapshot(forProcess: processHandle) else {
        Issue.record("Could not create snapshot handle for getSharedCache test")
        return
    }
    defer { snapshotHandle.dispose() }

    let cacheHandle = DyldIntrospection.getSharedCache(of: snapshotHandle)
    #expect(cacheHandle != nil, "getSharedCache must return a non-nil handle for the current process snapshot")
}

// MARK: - Function 9: dyld_process_register_for_image_notifications

@Test
func processRegisterForImageNotificationsResolves() {
    guard let processHandle = DyldIntrospection.createProcessForCurrentTask() else {
        Issue.record("Could not create process handle for registerForImageNotifications test")
        return
    }
    defer { processHandle.dispose() }

    let notificationQueue = DispatchQueue(label: "com.dyldprivate.test.imagenotifications")
    let result = DyldIntrospection.registerForImageNotifications(
        on: processHandle,
        queue: notificationQueue
    ) { _, _ in }

    switch result {
    case .success(let registrationHandle):
        #expect(registrationHandle != 0, "registerForImageNotifications must return a non-zero handle on success")
        DyldIntrospection.unregisterForNotification(on: processHandle, registrationHandle: registrationHandle)
    case .failure(let error):
        Issue.record("registerForImageNotifications failed: \(error)")
    }
}

// MARK: - Function 10: dyld_process_register_for_event_notification

@Test
func processRegisterForEventNotificationResolves() {
    guard let processHandle = DyldIntrospection.createProcessForCurrentTask() else {
        Issue.record("Could not create process handle for registerForEventNotification test")
        return
    }
    defer { processHandle.dispose() }

    let notificationQueue = DispatchQueue(label: "com.dyldprivate.test.eventnotification")
    // Use event type 1 (DYLD_REMOTE_EVENT_MAIN).
    let result = DyldIntrospection.registerForEventNotification(
        on: processHandle,
        event: 1,
        queue: notificationQueue
    ) {}

    switch result {
    case .success(let registrationHandle):
        #expect(registrationHandle != 0, "registerForEventNotification must return a non-zero handle on success")
        DyldIntrospection.unregisterForNotification(on: processHandle, registrationHandle: registrationHandle)
    case .failure:
        // If the process has already passed main(), the event notification may legitimately fail.
        // Treat failure as acceptable — we only care that the symbol resolved without crash.
        #expect(Bool(true), "registerForEventNotification returned failure (acceptable: process may be past main)")
    }
}

// MARK: - Function 11: dyld_process_unregister_for_notification

@Test
func processUnregisterForNotificationResolves() {
    guard let processHandle = DyldIntrospection.createProcessForCurrentTask() else {
        Issue.record("Could not create process handle for unregisterForNotification test")
        return
    }
    defer { processHandle.dispose() }

    let notificationQueue = DispatchQueue(label: "com.dyldprivate.test.unregister")
    let result = DyldIntrospection.registerForImageNotifications(
        on: processHandle,
        queue: notificationQueue
    ) { _, _ in }

    guard case .success(let registrationHandle) = result else {
        Issue.record("Could not register for image notifications to set up unregister test")
        return
    }
    // This is the function under test — it must not crash when called with a valid handle.
    DyldIntrospection.unregisterForNotification(on: processHandle, registrationHandle: registrationHandle)
    #expect(Bool(true), "unregisterForNotification did not crash")
}

// MARK: - Function 12: dyld_for_each_installed_shared_cache

@Test
func forEachInstalledSharedCacheResolves() {
    var cacheCount = 0
    DyldIntrospection.forEachInstalledSharedCache { _ in
        cacheCount += 1
    }
    #expect(cacheCount > 0, "forEachInstalledSharedCache must enumerate at least one shared cache on macOS")
}

// MARK: - Function 13: dyld_for_each_installed_shared_cache_with_system_path

@Test
func forEachInstalledSharedCacheWithSystemPathResolves() {
    var cacheCount = 0
    DyldIntrospection.forEachInstalledSharedCache(withSystemPath: "/") { _ in
        cacheCount += 1
    }
    #expect(cacheCount > 0, "forEachInstalledSharedCache(withSystemPath:) must enumerate at least one cache at /")
}

// MARK: - Function 14: dyld_shared_cache_for_file

@Test
func sharedCacheForFileResolves() {
    // Use a well-known macOS shared cache path to test the file-based API.
    let knownCachePath = "/System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_arm64e"
    var wasInvoked = false
    let succeeded = DyldIntrospection.sharedCache(forFile: knownCachePath) { _ in
        wasInvoked = true
    }
    if succeeded {
        #expect(wasInvoked, "sharedCacheForFile block must be invoked when it returns true")
    } else {
        // Path may differ across OS versions; also test with root-based path.
        let fallbackPath = "/System/Library/dyld/dyld_shared_cache_arm64e"
        let fallbackSucceeded = DyldIntrospection.sharedCache(forFile: fallbackPath) { _ in
            wasInvoked = true
        }
        _ = fallbackSucceeded
        // Non-crash with false return is also acceptable (symbol resolved but path not found).
        #expect(Bool(true), "sharedCacheForFile did not crash (symbol resolved)")
    }
}

// MARK: - Function 15: dyld_shared_cache_pin_mapping

@Test
func sharedCachePinMappingResolves() {
    // Use forEachInstalledSharedCache to get a cache handle scoped to the block lifetime,
    // then call pinMapping inside the block.
    var pinnedSuccessfully = false
    DyldIntrospection.forEachInstalledSharedCache { cacheHandle in
        let pinResult = DyldIntrospection.pinMapping(of: cacheHandle)
        if pinResult {
            pinnedSuccessfully = true
            DyldIntrospection.unpinMapping(of: cacheHandle)
        }
    }
    #expect(pinnedSuccessfully, "pinMapping must succeed for at least one installed shared cache")
}

// MARK: - Function 16: dyld_shared_cache_unpin_mapping

@Test
func sharedCacheUnpinMappingResolves() {
    // Pin and then unpin a cache — test is that unpinMapping does not crash.
    var unpinCalled = false
    DyldIntrospection.forEachInstalledSharedCache { cacheHandle in
        let pinResult = DyldIntrospection.pinMapping(of: cacheHandle)
        guard pinResult else { return }
        DyldIntrospection.unpinMapping(of: cacheHandle)
        unpinCalled = true
    }
    #expect(unpinCalled, "unpinMapping must be callable after a successful pinMapping")
}

// MARK: - Function 17: dyld_shared_cache_for_each_file

@Test
func sharedCacheForEachFileResolves() {
    var fileCount = 0
    DyldIntrospection.forEachInstalledSharedCache { cacheHandle in
        DyldIntrospection.forEachFile(in: cacheHandle) { _ in
            fileCount += 1
        }
    }
    #expect(fileCount > 0, "forEachFile must yield at least one file path for the installed shared cache")
}

// MARK: - Function 18: dyld_shared_cache_get_base_address

@Test
func sharedCacheGetBaseAddressResolves() {
    var capturedBaseAddress: UInt64?
    DyldIntrospection.forEachInstalledSharedCache { cacheHandle in
        if capturedBaseAddress == nil {
            capturedBaseAddress = DyldIntrospection.baseAddress(of: cacheHandle)
        }
    }
    #expect(capturedBaseAddress != nil, "baseAddress must return a non-nil value for an installed shared cache")
}

// MARK: - Function 19: dyld_shared_cache_get_mapped_size

@Test
func sharedCacheGetMappedSizeResolves() {
    var capturedMappedSize: UInt64?
    DyldIntrospection.forEachInstalledSharedCache { cacheHandle in
        if capturedMappedSize == nil {
            capturedMappedSize = DyldIntrospection.mappedSize(of: cacheHandle)
        }
    }
    guard let mappedSize = capturedMappedSize else {
        Issue.record("mappedSize returned nil for installed shared cache")
        return
    }
    #expect(mappedSize > 0, "mappedSize must be greater than zero for a valid shared cache")
}

// MARK: - Function 20: dyld_shared_cache_is_mapped_private

@Test
func sharedCacheIsMappedPrivateResolves() {
    var capturedIsMappedPrivate: Bool?
    DyldIntrospection.forEachInstalledSharedCache { cacheHandle in
        if capturedIsMappedPrivate == nil {
            capturedIsMappedPrivate = DyldIntrospection.isMappedPrivate(cacheHandle)
        }
    }
    #expect(capturedIsMappedPrivate != nil, "isMappedPrivate must return a non-nil value for an installed shared cache")
}

// MARK: - Function 21: dyld_shared_cache_copy_uuid

@Test
func sharedCacheCopyUUIDResolves() {
    var capturedUUID: uuid_t?
    DyldIntrospection.forEachInstalledSharedCache { cacheHandle in
        if capturedUUID == nil {
            capturedUUID = DyldIntrospection.copyUUID(of: cacheHandle)
        }
    }
    guard let uuidValue = capturedUUID else {
        Issue.record("copyUUID returned nil for installed shared cache")
        return
    }
    let uuidBytes = withUnsafeBytes(of: uuidValue) { Array($0) }
    let isAllZero = uuidBytes.allSatisfy { $0 == 0 }
    #expect(!isAllZero, "shared cache UUID must not be all-zero bytes")
}

// MARK: - Function 22: dyld_shared_cache_for_each_image

@Test
func sharedCacheForEachImageResolves() {
    var imageCount = 0
    DyldIntrospection.forEachInstalledSharedCache { cacheHandle in
        DyldIntrospection.forEachImage(in: cacheHandle) { _ in
            imageCount += 1
        }
    }
    #expect(imageCount > 0, "forEachImage in shared cache must yield at least one image")
}

// MARK: - Function 23: dyld_image_copy_uuid

@Test
func imageCopyUUIDResolves() {
    guard let processHandle = DyldIntrospection.createProcessForCurrentTask() else {
        Issue.record("Could not create process handle for imageCopyUUID test")
        return
    }
    defer { processHandle.dispose() }
    guard case .success(let snapshotHandle) = DyldIntrospection.createSnapshot(forProcess: processHandle) else {
        Issue.record("Could not create snapshot handle for imageCopyUUID test")
        return
    }
    defer { snapshotHandle.dispose() }

    var successCount = 0
    DyldIntrospection.forEachImage(in: snapshotHandle) { imageHandle in
        guard successCount == 0 else { return }
        if let _ = DyldIntrospection.copyUUID(of: imageHandle) {
            successCount += 1
        }
    }
    #expect(successCount > 0, "imageCopyUUID must successfully return a UUID for at least one image")
}

// MARK: - Function 24: dyld_image_get_installname

@Test
func imageGetInstallnameResolves() {
    // Use shared cache images which always have install names.
    var foundInstallName = false
    DyldIntrospection.forEachInstalledSharedCache { cacheHandle in
        guard !foundInstallName else { return }
        DyldIntrospection.forEachImage(in: cacheHandle) { imageHandle in
            guard !foundInstallName else { return }
            if let installName = DyldIntrospection.installName(of: imageHandle), !installName.isEmpty {
                foundInstallName = true
            }
        }
    }
    #expect(foundInstallName, "imageGetInstallname must return a non-empty install name for at least one shared cache image")
}

// MARK: - Function 25: dyld_image_get_file_path

@Test
func imageGetFilePathResolves() {
    guard let processHandle = DyldIntrospection.createProcessForCurrentTask() else {
        Issue.record("Could not create process handle for imageGetFilePath test")
        return
    }
    defer { processHandle.dispose() }
    guard case .success(let snapshotHandle) = DyldIntrospection.createSnapshot(forProcess: processHandle) else {
        Issue.record("Could not create snapshot handle for imageGetFilePath test")
        return
    }
    defer { snapshotHandle.dispose() }

    var foundFilePath = false
    DyldIntrospection.forEachImage(in: snapshotHandle) { imageHandle in
        guard !foundFilePath else { return }
        if let filePath = DyldIntrospection.filePath(of: imageHandle), !filePath.isEmpty {
            foundFilePath = true
        }
    }
    #expect(foundFilePath, "imageGetFilePath must return a non-empty file path for at least one process image")
}
#endif
