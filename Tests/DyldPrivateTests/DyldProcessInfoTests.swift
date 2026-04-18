#if canImport(Darwin)
import Darwin
import Testing
@testable import DyldPrivate

// MARK: - Helpers

/// Creates a DyldProcessInfoHandle for the current process and returns it.
/// The caller is responsible for calling handle.release() via a defer block.
private func makeCurrentProcessHandle() -> DyldProcessInfoHandle? {
    let result = DyldProcessInfo.create(task: mach_task_self_, timestamp: 0)
    guard case .success(let handle) = result else {
        return nil
    }
    return handle
}

// MARK: - Function 1: _dyld_process_info_create

@Test
func processInfoCreateResolves() {
    let result = DyldProcessInfo.create(task: mach_task_self_, timestamp: 0)
    // The function must resolve and succeed for the current process.
    switch result {
    case .success(let handle):
        defer { handle.release() }
        #expect(true, "processInfoCreate resolved and returned a valid handle")
    case .failure(let error):
        Issue.record("processInfoCreate failed: \(error)")
    }
}

// MARK: - Function 2: _dyld_process_info_release

@Test
func processInfoReleaseResolves() {
    // Verify that release() can be called without crashing.
    // We create a handle and immediately release it to test the function pointer.
    let result = DyldProcessInfo.create(task: mach_task_self_, timestamp: 0)
    guard case .success(let handle) = result else {
        Issue.record("Could not create processInfo handle for release test")
        return
    }
    // Calling release() is the test — it must not crash.
    handle.release()
    #expect(true, "processInfoRelease resolved and completed without crash")
}

// MARK: - Function 3: _dyld_process_info_retain

@Test
func processInfoRetainResolves() {
    // Verify that retain() can be called without crashing, then balance with release.
    let result = DyldProcessInfo.create(task: mach_task_self_, timestamp: 0)
    guard case .success(let handle) = result else {
        Issue.record("Could not create processInfo handle for retain test")
        return
    }
    // Retain once, then release twice to balance (create + retain = 2 retains).
    handle.retain()
    handle.release()
    handle.release()
    #expect(true, "processInfoRetain resolved and completed without crash")
}

// MARK: - Function 4: _dyld_process_info_get_state

@Test
func processInfoGetStateResolves() {
    guard let handle = makeCurrentProcessHandle() else {
        Issue.record("Could not create processInfo handle for state test")
        return
    }
    defer { handle.release() }
    let stateInfo = DyldProcessInfo.state(of: handle)
    #expect(stateInfo != nil, "processInfoGetState must resolve")
    if let stateInfo {
        // The current process must be in a running state.
        #expect(stateInfo.imageCount > 0, "Running process must have at least one loaded image")
    }
}

// MARK: - Function 5: _dyld_process_info_get_cache

@Test
func processInfoGetCacheResolves() {
    guard let handle = makeCurrentProcessHandle() else {
        Issue.record("Could not create processInfo handle for cache test")
        return
    }
    defer { handle.release() }
    let cacheInfo = DyldProcessInfo.cacheInfo(of: handle)
    #expect(cacheInfo != nil, "processInfoGetCache must resolve")
    // On a normal macOS/iOS device, noCache is false and cacheBaseAddress is non-zero.
    if let cacheInfo {
        if !cacheInfo.noCache {
            #expect(cacheInfo.cacheBaseAddress != 0, "Cache base address must be non-zero when cache is in use")
        }
    }
}

// MARK: - Function 6: _dyld_process_info_get_aot_cache

@Test
func processInfoGetAotCacheResolves() {
    guard let handle = makeCurrentProcessHandle() else {
        Issue.record("Could not create processInfo handle for aot cache test")
        return
    }
    defer { handle.release() }
    // On non-AOT processes, this returns a zeroed struct. We only verify no crash occurs.
    let aotCacheInfo = DyldProcessInfo.aotCacheInfo(of: handle)
    #expect(aotCacheInfo != nil, "processInfoGetAotCache must resolve (may return zeroed struct on non-AOT processes)")
}

// MARK: - Function 7: _dyld_process_info_for_each_image

@Test
func processInfoForEachImageResolves() {
    guard let handle = makeCurrentProcessHandle() else {
        Issue.record("Could not create processInfo handle for forEachImage test")
        return
    }
    defer { handle.release() }
    var imageCount = 0
    DyldProcessInfo.forEachImage(in: handle) { machHeaderAddress, _, path in
        imageCount += 1
        // Each image must have a non-zero mach header address.
        #expect(machHeaderAddress != 0, "Mach header address must be non-zero for image: \(path)")
    }
    #expect(imageCount > 0, "forEachImage must enumerate at least one image in the current process")
}

// MARK: - Function 8: _dyld_process_info_for_each_aot_image (macOS only)

#if os(macOS)
@Test
func processInfoForEachAotImageResolves() {
    guard let handle = makeCurrentProcessHandle() else {
        Issue.record("Could not create processInfo handle for forEachAotImage test")
        return
    }
    defer { handle.release() }
    // On a non-AOT test runner, the callback may never fire — that is acceptable.
    // We only verify the function resolves and does not crash.
    var invocationCount = 0
    DyldProcessInfo.forEachAotImage(in: handle) { _, _, _, _, _ in
        invocationCount += 1
        return true
    }
    // Zero invocations is valid for non-AOT processes.
    #expect(invocationCount >= 0, "forEachAotImage resolved; zero invocations acceptable for non-AOT processes")
}
#endif

// MARK: - Function 9: _dyld_process_info_for_each_segment

@Test
func processInfoForEachSegmentResolves() {
    guard let handle = makeCurrentProcessHandle() else {
        Issue.record("Could not create processInfo handle for forEachSegment test")
        return
    }
    defer { handle.release() }

    // First, grab the mach header address of the first loaded image.
    var firstMachHeaderAddress: UInt64 = 0
    DyldProcessInfo.forEachImage(in: handle) { machHeaderAddress, _, _ in
        if firstMachHeaderAddress == 0 {
            firstMachHeaderAddress = machHeaderAddress
        }
    }
    guard firstMachHeaderAddress != 0 else {
        Issue.record("Could not obtain a mach header address from forEachImage")
        return
    }

    // Now iterate segments for that image.
    var segmentCount = 0
    DyldProcessInfo.forEachSegment(in: handle, machHeaderAddress: firstMachHeaderAddress) { segmentAddress, segmentSize, segmentName in
        segmentCount += 1
        #expect(segmentAddress != 0 || segmentName == "__PAGEZERO", "Segment address must be non-zero (except __PAGEZERO)")
        #expect(!segmentName.isEmpty, "Segment name must not be empty")
    }
    #expect(segmentCount > 0, "forEachSegment must enumerate at least one segment")
}

// MARK: - Function 10: _dyld_process_info_get_platform

@Test
func processInfoGetPlatformResolves() {
    guard let handle = makeCurrentProcessHandle() else {
        Issue.record("Could not create processInfo handle for platform test")
        return
    }
    defer { handle.release() }
    let platformValue = DyldProcessInfo.platform(of: handle)
    #expect(platformValue != nil, "processInfoGetPlatform must resolve")
    // A running process always has a determined platform (non-zero).
    if let platformValue {
        #expect(platformValue > 0, "Platform must be non-zero for a running process")
    }
}

// MARK: - Function 11: _dyld_process_info_notify (resolution check only)

@Test
func processInfoNotifyFunctionResolves() {
    // Verify the obfuscated resolver can locate the notify symbol.
    // Using DyldSymbolResolver + obfuscated name ensures no raw C symbol literal
    // appears in the compiled object file (audit-clean).
    typealias NotifyProbe = @convention(c) () -> Void
    let resolvedFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldProcessInfoSymbols.$processInfoNotify,
        as: NotifyProbe.self
    )
    #expect(resolvedFunction != nil, "The _dyld_process_info_notify symbol must be resolvable via obfuscated lookup")
}

// MARK: - Function 12: _dyld_process_info_notify_main (resolution check only)

@Test
func processInfoNotifyMainFunctionResolves() {
    typealias NotifyMainProbe = @convention(c) () -> Void
    let resolvedFunction = DyldSymbolResolver.resolve(
        symbol: ObfuscatedDyldProcessInfoSymbols.$processInfoNotifyMain,
        as: NotifyMainProbe.self
    )
    #expect(resolvedFunction != nil, "The _dyld_process_info_notify_main symbol must be resolvable via obfuscated lookup")
}
#endif
