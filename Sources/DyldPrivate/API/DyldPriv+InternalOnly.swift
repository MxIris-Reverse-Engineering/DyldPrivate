#if canImport(Darwin)
// MARK: - Documented skips
//
// The following symbols exist in <mach-o/dyld_priv.h> but are deliberately NOT wrapped:
//
// • `_dyld_initializer()` — dyld itself calls this function once at startup. It is not
//   intended for consumer code; invoking it from a client would have undefined
//   behavior and no useful effect.
//
// • `dyld_stub_binder()` — an assembly entry point used by the dynamic linker's
//   lazy-binding stub pad. It is not a callable C function; it is the label of the
//   code the linker jumps to when resolving a lazy stub. No Swift binding is possible
//   or meaningful.
//
// Consumers who need to reference these symbols at link time can import the
// DyldPrivateC umbrella module and declare their own `@_silgen_name` shim, but that
// defeats the obfuscation guarantee of this package and is not supported here.
#endif
