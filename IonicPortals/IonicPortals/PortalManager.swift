import Foundation
import UIKit

/// Maintains a registry of ``Portal``s for the lifecycle of an application
@objc(IONPortalManager)
public class PortalManager: NSObject {
    enum RegistrationState {
        case unregistered(messageShown: Bool)
        case registered
        case error
    }
    
    private override init() {}
    
    /// The default singleton
    @objc public static let shared = PortalManager()

    private var portals: [String: Portal] = [:]
    private var registrationState: RegistrationState = .unregistered(messageShown: false)

    /// Whether Portals has been registered.
    /// Will be true when ``register(key:)`` has been called with a valid key.
    @objc public var isRegistered: Bool {
        switch registrationState {
        case .unregistered, .error:
            return false
        case .registered:
            return true
        }
    }
    
    /// The number of ``Portal``s added
    @objc public var count: Int { portals.count }
    
    /// Adds a ``Portal`` to ``PortalManager``
    /// - Parameter portal: The ``Portal`` to add
    public func add(_ portal: Portal) {
        portals[portal.name] = portal
        
        if case .unregistered(messageShown: false) = registrationState {
            unregisteredMessage()
        }
    }
    
    /// Adds an ``IONPortal`` to ``PortalManager``
    /// - Parameter portal: The ``IONPortal`` to add
    ///
    /// This method is meant to be used for Objective-C interop. The ``add(_:)`` method is preferred if being called from Swift
    @objc public func addPortal(_ portal: IONPortal) {
        add(portal.portal)
    }
    
    /// Returns a ``Portal`` given the name of the portal
    /// - Parameter name: The Portal name
    /// - returns: The existing ``Portal`` with name `name`.
    /// Returns `nil` if the ``Portal`` has not been added via ``add(_:)`` or if a registration error has occured
    public func getPortal(named name: String) -> Portal? {
        if case .error = registrationState {
            registrationError()
            return nil
        }
        
        return portals[name]
    }
    
    /// Returns an ``IONPortal`` given the name of the portal
    /// - Parameter name: The IONPortal name
    /// - returns: The existing ``IONPortal`` with name `name`.
    /// Returns `nil` if the ``IONPortal`` has not been added via ``add(_:)``, ``addPortal(_:)``, or if a registration error has occured
    ///
    /// This method is meant to be used for Objective-C interop. The ``getPortal(named:)`` method is preferred if being called from Swift.
    @objc public func getPortalNamed(_ name: String) -> IONPortal? {
        getPortal(named: name).map(IONPortal.init(portal:))
    }
    
    /// Validates that a valid registration key has been procured from http://ionic.io/register-portals
    /// - Parameter key: The registration key
    @objc public func register(key: String) {
        registrationState = validate(key)
    }
    
    private func base64(from base64Url: String) -> String {
        var base64 = base64Url
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: base64.count % 4)
        return base64
    }
    
    private func validate(_ token: String) -> RegistrationState {
        let publicKeyBase64 =
        "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1+gMC3aJVGX4ha5asmEF" +
        "TfP0FTFQlCD8d/J+dhp5dpx3ErqSReru0QSUaCRCEGV/ZK3Vp5lnv1cREQDG5H/t" +
        "Xm9Ao06b0QJYtsYhcPgRUU9awDI7jRKueXyAq4zAx0RHZlmOsTf/cNwRnmRnkyJP" +
        "a21mLNClmdPlhWjS6AHjaYe79ieAsftFA+QodtzoCo+w9A9YCvc6ngGOFoLIIbzs" +
        "jv6h9ES27mi5BUqhoHsetS4u3/pCbsV2U3z255gtjANtdIX/c5inepLuAjyc1aPz" +
        "2eu4TbzabvJnmNStje82NW36Qij1mupc4e7dYaq0aMNQyHSWk1/CuIcqEYlnK1mb" +
        "kQIDAQAB"
        
        let pubKeyData = Data(base64Encoded: publicKeyBase64)
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic
        ]
        let publicKey = SecKeyCreateWithData(pubKeyData! as NSData, attributes as NSDictionary, nil)!
        
        let parts = token.split(separator: ".")
        if parts.count != 3 {
            registrationError()
            return .error
        }
        let headerAndPayload = "\(parts[0]).\(parts[1])"
        let signature = String(parts[2])
        
        let headersAndPayloadData = headerAndPayload.data(using: .ascii)! as CFData
        let signatureData = Data(base64Encoded: base64(from: signature))! as CFData
        
        var error: Unmanaged<CFError>?
        
        let result = SecKeyVerifySignature(
            publicKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            headersAndPayloadData,
            signatureData,
            &error
        )
        
        let state: RegistrationState = result ? .registered : .error
        
        if case .error = state {
            registrationError()
        }
        
        return state
    }
    
    private func registrationError() {
        print("Error validating key")
        
        let alert = UIAlertController(title: nil, message: "Error validating your key for Ionic Portals. Check your key and try again.", preferredStyle: .alert)
        let okButton = UIAlertAction(title: "OK", style: .default, handler: { action -> Void in alert.dismiss(animated: true) })
        
        alert.addAction(okButton)
        
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        keyWindow?.rootViewController = alert
    }
    
    private func unregisteredMessage() {
        if case .unregistered(messageShown: false) = registrationState {
            print("Don't forget to register your copy of portals! Register at: ionic.io/register-portals")
            registrationState = .unregistered(messageShown: true)
        }
    }
}

