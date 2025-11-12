// Gate-1b: UITest seam hardening
// Shared entry point so all services know if UITest seams are compiled in.
enum BuildFlags {
#if DEBUG || PULSUM_UITESTS
    static let uiTestSeamsCompiledIn = true
#else
    static let uiTestSeamsCompiledIn = false
#endif
}
