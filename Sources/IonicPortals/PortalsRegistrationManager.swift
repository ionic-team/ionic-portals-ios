import Foundation

/// Registration is no longer required for Ionic Portals.
@available(*, deprecated, message: "Registration is no longer required.")
@objc(IONPortalsRegistrationManager)
public class PortalsRegistrationManager: NSObject {
    private override init() {}
    
    /// The default singleton
    @objc public static let shared = PortalsRegistrationManager()

    /// Always `true`. Registration is no longer required.
    @objc public var isRegistered: Bool {
        true
    }
    
    /// No-op. Registration is no longer required.
    /// - Parameter key: Ignored.
    @objc public func register(key: String) {
    }
}
