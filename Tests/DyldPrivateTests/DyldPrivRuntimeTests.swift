#if canImport(Darwin)
import Testing
@testable import DyldPrivate

@Test
func launchModeResolves() {
    // Live-invoke: _dyld_launch_mode has no side effects and returns a simple flags value.
    // Both zero and non-zero are valid; we only require that the function resolves.
    let launchModeValue = DyldPriv.launchMode()
    #expect(launchModeValue != nil)
}
#endif
