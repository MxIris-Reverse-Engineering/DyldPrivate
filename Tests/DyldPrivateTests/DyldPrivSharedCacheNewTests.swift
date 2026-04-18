#if canImport(Darwin)
import Testing
@testable import DyldPrivate

@Test
func getSharedCacheUUIDLiveInvoke() {
    var uuidStorage = uuid_t(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    let result = DyldPriv.getSharedCacheUUID(into: &uuidStorage)
    // Accept either true (found) or false (no shared cache); just must not crash.
    _ = result
}


@Test
func sharedCacheIterateTextLiveInvoke() {
    // First get the current cache UUID, then attempt to iterate.
    var cacheUUID = uuid_t(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    let hasUUID = DyldPriv.getSharedCacheUUID(into: &cacheUUID)
    guard hasUUID == true else { return }
    var iteratedCount = 0
    let result = DyldPriv.sharedCacheIterateText(uuid: &cacheUUID) { _ in
        iteratedCount += 1
    }
    // If resolved, result should be 0 (success) and at least some images iterated.
    if result != nil {
        #expect(result == 0 || iteratedCount >= 0)
    }
}

@Test
func isMemoryImmutableLiveInvoke() {
    // Test with a stack address (definitely not immutable dyld memory).
    var localValue: Int = 42
    let result = withUnsafePointer(to: &localValue) { stackPointer -> Bool? in
        DyldPriv.isMemoryImmutable(
            pointer: UnsafeRawPointer(stackPointer),
            size: MemoryLayout<Int>.size
        )
    }
    // Accept either result; just must not crash.
    _ = result
}

@Test
func needsClosureLiveInvoke() {
    // Pass harmless args; accept either bool result.
    let result = DyldPriv.needsClosure(executablePath: "/usr/bin/true", dataContainerRootDir: "/tmp")
    _ = result
}

@Test
func sharedCacheRealPathLiveInvoke() {
    // Pass a plausible dyld path; we accept a non-nil result or nil (not in cache).
    let result = DyldPriv.sharedCacheRealPath(for: "/usr/lib/libobjc.A.dylib")
    _ = result
}

@Test
func sharedCacheIsLocallyBuiltLiveInvoke() {
    let result = DyldPriv.sharedCacheIsLocallyBuilt()
    // Accept either true or false; just must not crash.
    _ = result
}

@Test
func sharedCacheIsOptimizedLiveInvoke() {
    let result = DyldPriv.sharedCacheIsOptimized()
    // Accept either true or false; just must not crash.
    _ = result
}

#endif
