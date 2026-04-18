#if canImport(Darwin)
import Testing
import DyldPrivate

@Test
func machHeaderTypeIsReExportedFromSwiftModule() {
    // If the @_exported import works, `mach_header` resolves via `import DyldPrivate` alone.
    let header = mach_header()
    #expect(header.magic == 0)
}
#endif
