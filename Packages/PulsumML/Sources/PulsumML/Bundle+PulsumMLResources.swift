import Foundation

#if SWIFT_PACKAGE
extension Bundle {
    static var pulsumMLResources: Bundle { .module }
}
#else
private final class PulsumMLBundleToken {}
extension Bundle {
    static var pulsumMLResources: Bundle { Bundle(for: PulsumMLBundleToken.self) }
}
#endif
