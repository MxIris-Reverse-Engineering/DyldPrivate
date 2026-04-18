#if canImport(Darwin)
import Testing
@testable import DyldPrivate

@Test
func nxArgcResolves() {
    // Live-invoke: NXArgc is a libc global; it is always ≥ 1 for a launched process.
    let argumentCount = DyldPriv.nxArgc
    #expect(argumentCount != nil)
    if let argumentCount {
        #expect(argumentCount >= 1)
    }
}

@Test
func nxArgvResolves() {
    // Live-invoke: NXArgv[0] should be a non-null pointer to the program path.
    let argumentVector = DyldPriv.nxArgv
    #expect(argumentVector != nil)
    if let argumentVector {
        // argv[0] (program name) must be non-nil for any normally launched process.
        #expect(argumentVector[0] != nil)
    }
}

@Test
func environResolves() {
    // Live-invoke: environ is a POSIX global; it should be non-nil and
    // the array should be null-terminated (first entry may be non-nil or nil depending
    // on whether any env vars are set, but the pointer itself must not be nil).
    let environmentVector = DyldPriv.environ
    #expect(environmentVector != nil)
}
#endif
