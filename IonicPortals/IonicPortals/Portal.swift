import Foundation
import Capacitor
import IonicLiveUpdates

/// The configuration of a web application to be embedded in an iOS application
public struct Portal {
    
    /// The name of the portal
    public let name: String
    
    /// The root directory of the ``Portal`` relative to root of the `Bundle`
    public let startDir: String
    
    /// Any initial state required by the web application
    public var initialContext: [String: JSValue]
    
    /// The `LiveUpdate` configuration used to determine the location of updated application assets.
    public var liveUpdateConfig: LiveUpdate? = nil {
        didSet {
            guard let liveUpdateConfig = liveUpdateConfig else { return }
            try? LiveUpdateManager.shared.add(liveUpdateConfig)
        }
    }
    
    /// Creates an instance of ``Portal``
    /// - Parameters:
    ///   - name: The name of the portal, must be unique.
    ///   - startDir: The starting directory of the ``Portal`` relative to the root of the ``Bundle``.
    ///     If `nil`, the portal name is used as the starting directory. Defaults to `nil`.
    ///   - initialContext: Any initial state rqeuired by the web application. Defaults to `[:]`.
    ///   - liveUpdateConfig: The `LiveUpdate` configuration used to determine to location of updated application assets. Defaults to `nil`.
    public init(name: String, startDir: String? = nil, initialContext: [String: JSValue] = [:], liveUpdateConfig: LiveUpdate? = nil) {
        self.name = name
        self.startDir = startDir ?? name
        self.initialContext = initialContext
        self.liveUpdateConfig = liveUpdateConfig
        if let liveUpdateConfig = liveUpdateConfig {
            try? LiveUpdateManager.shared.add(liveUpdateConfig)
        }
    }
}

extension Portal: ExpressibleByStringLiteral {
    
    /// ExpressibleByStringLiteral conformance for ``Portal``.
    /// - Parameter value: The name of the portal
    ///
    /// Creates a ``Portal`` as if being called with the initializer as `Portal(name: "stringliteral")`
    public init(stringLiteral value: StringLiteralType) {
        self.init(name: value)
    }
}

/// The objective-c representation of ``Portal``. If using Swift, ``Portal`` is preferred since it provides better type constraints.
@objc public class IONPortal: NSObject {
    internal var portal: Portal
    
    /// The name of the portal
    @objc public var name: String { portal.name }
    
    /// The root directory of the ``Portal`` relative to root of the `Bundle`
    @objc public var startDir: String { portal.startDir }
    
    /// Any initial state required by the web application.
    ///
    /// The following types are valid values:
    /// * NSNumber
    /// * NSString
    /// * NSArray
    /// * NSDate
    /// * NSNull
    /// * NSDictionary keyed by a String and the value is any valid JS Value
    @objc public var initialContext: [String: Any] {
        get { portal.initialContext }
        set {
            guard let context = newValue as? [String: JSValue] else { return }
            portal.initialContext = context
        }
    }
    
    internal init(portal: Portal) {
        self.portal = portal
    }
    
    /// Configures the `LiveUpdate` configuration
    /// - Parameters:
    ///   - appId: The AppFlow id of the web application associated with the ``IONPortal``
    ///   - channel: The AppFlow channel to check for updates from.
    ///   - syncImmediately: Whether to immediately sync with AppFlow to check for updates.
    @objc public func setLiveUpdateConfiguration(appId: String, channel: String, syncImmediately: Bool) {
        portal.liveUpdateConfig = LiveUpdate(appId: appId, channel: channel, syncOnAdd: syncImmediately)
    }
}

extension IONPortal {
    /// Creates an instance of ``Portal``
    /// - Parameters:
    ///   - name: The name of the portal, must be unique.
    ///   - startDir: The starting directory of the ``Portal`` relative to the root of the ``Bundle``.
    ///     If `nil`, the portal name is used as the starting directory.
    ///   - initialContext: Any initial state rqeuired by the web application. Defaults to `[:]`.
    ///
    /// The following types are valid values in `initialContext`:
    /// * NSNumber
    /// * NSString
    /// * NSArray
    /// * NSDate
    /// * NSNull
    /// * NSDictionary keyed by a String and the value is any valid JS Value
    @objc public convenience init(name: String, startDir: String?, initialContext: [String: Any]?) {
        let portal = Portal(name: name, startDir: startDir, initialContext: initialContext as? [String: JSValue] ?? [:], liveUpdateConfig: nil)
        self.init(portal: portal)
    }
}
