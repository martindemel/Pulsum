import Foundation

#if SWIFT_PACKAGE
extension Bundle {
    static var pulsumServicesResources: Bundle { .module }
}
#else
private final class PulsumServicesBundleLocator {}
extension Bundle {
    static var pulsumServicesResources: Bundle {
        Bundle(for: PulsumServicesBundleLocator.self)
    }
}
#endif
