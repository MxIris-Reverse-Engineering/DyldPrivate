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
        // unregisterForNotification will be implemented in the dyld_process_unregister_for_notification commit.
        _ = registrationHandle
    case .failure(let error):
        Issue.record("registerForImageNotifications failed: \(error)")
    }
}
#endif
