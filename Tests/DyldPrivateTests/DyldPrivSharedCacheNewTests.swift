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
