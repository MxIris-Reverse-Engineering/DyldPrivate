#if canImport(Darwin)
import Darwin
import Testing
@testable import DyldPrivate

// Helper: obtain a mach_header* for a well-known loaded image (the image containing dlsym).
private func knownImageHeader() -> UnsafePointer<mach_header>? {
    let rtldDefault = UnsafeMutableRawPointer(bitPattern: -2)
    guard let symbolPointer = dlsym(rtldDefault, "dlsym") else {
        return nil
    }
    guard let rawHeader = DyldPriv.imageHeader(containing: UnsafeRawPointer(symbolPointer)) else {
        return nil
    }
    return rawHeader.assumingMemoryBound(to: mach_header.self)
}

@Test
func programSdkAtLeastResolves() {
    guard let activePlatform = DyldPriv.getActivePlatform() else {
        Issue.record("could not obtain active platform for testing")
        return
    }
    // Version 0 must always be satisfied by any binary.
    let zeroVersion = dyld_build_version_t(platform: activePlatform, version: 0)
    let result = DyldPriv.programSdkAtLeast(zeroVersion)
    #expect(result != nil)
    if let result {
        #expect(result == true)
    }
}

@Test
func programMinosAtLeastResolves() {
    guard let activePlatform = DyldPriv.getActivePlatform() else {
        Issue.record("could not obtain active platform for testing")
        return
    }
    // Version 0 must always be satisfied by any binary.
    let zeroVersion = dyld_build_version_t(platform: activePlatform, version: 0)
    let result = DyldPriv.programMinosAtLeast(zeroVersion)
    #expect(result != nil)
    if let result {
        #expect(result == true)
    }
}

@Test
func programSdkVersionTokenResolves() {
    // This SPI is available from macOS 15 / iOS 18. On older OS it may return nil; that's acceptable.
    let tokenValue = DyldPriv.programSdkVersionToken()
    // If the symbol resolved, the token should be nonzero.
    if let tokenValue {
        #expect(tokenValue != 0)
    }
}

@Test
func programMinosVersionTokenResolves() {
    let tokenValue = DyldPriv.programMinosVersionToken()
    if let tokenValue {
        #expect(tokenValue != 0)
    }
}

@Test
func platformFromVersionTokenResolves() {
    guard let sdkToken = DyldPriv.programSdkVersionToken() else {
        // Symbol not available on this OS version.
        return
    }
    let platformValue = DyldPriv.platformFromVersionToken(sdkToken)
    #expect(platformValue != nil)
    if let platformValue {
        #expect(platformValue > 0)
    }
}

@Test
func versionTokenAtLeastResolves() {
    guard let activePlatform = DyldPriv.getActivePlatform(),
          let sdkToken = DyldPriv.programSdkVersionToken()
    else {
        return
    }
    let zeroVersion = dyld_build_version_t(platform: activePlatform, version: 0)
    let result = DyldPriv.versionTokenAtLeast(sdkToken, buildVersion: zeroVersion)
    #expect(result != nil)
    if let result {
        #expect(result == true)
    }
}

@Test
func enumerateImageVersionsResolves() {
    guard let machHeader = knownImageHeader() else {
        Issue.record("could not obtain mach_header for testing")
        return
    }
    var callbackInvokedCount = 0
    DyldPriv.enumerateImageVersions(of: machHeader) { _, _, _ in
        callbackInvokedCount += 1
    }
    // A well-known system dylib must have at least one version entry.
    #expect(callbackInvokedCount > 0)
}

@Test
func sdkVersionOfKnownImageResolves() {
    guard let machHeader = knownImageHeader() else {
        Issue.record("could not obtain mach_header for testing")
        return
    }
    let versionValue = DyldPriv.sdkVersion(of: machHeader)
    #expect(versionValue != nil)
    if let versionValue {
        #expect(versionValue > 0)
    }
}

@Test
func programSdkVersionResolves() {
    let versionValue = DyldPriv.programSdkVersion()
    #expect(versionValue != nil)
    if let versionValue {
        #expect(versionValue > 0)
    }
}

#if os(watchOS)
@Test
func programSdkWatchOSVersionResolves() {
    let versionValue = DyldPriv.programSdkWatchOSVersion()
    #expect(versionValue != nil)
    if let versionValue {
        #expect(versionValue > 0)
    }
}

@Test
func programMinWatchOSVersionResolves() {
    let versionValue = DyldPriv.programMinWatchOSVersion()
    #expect(versionValue != nil)
    if let versionValue {
        #expect(versionValue > 0)
    }
}
#endif
#endif
