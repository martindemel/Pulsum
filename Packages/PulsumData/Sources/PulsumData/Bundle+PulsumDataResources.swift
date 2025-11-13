import Foundation

#if SWIFT_PACKAGE
extension Bundle {
    static var pulsumDataResources: Bundle { .module }
}
#else
private final class PulsumDataBundleLocator {}
extension Bundle {
    static var pulsumDataResources: Bundle {
        Bundle(for: PulsumDataBundleLocator.self)
    }
}
#endif
