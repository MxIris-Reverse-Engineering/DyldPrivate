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

#endif
