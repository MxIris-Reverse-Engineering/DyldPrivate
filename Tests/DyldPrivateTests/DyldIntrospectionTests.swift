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
#endif
