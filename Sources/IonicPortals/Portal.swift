import Foundation
import Capacitor
import IonicLiveUpdates

/// The configuration of a web application to be embedded in an iOS application
public struct Portal {
    
    /// The name of the portal
    public let name: String
    
    /// The root directory of the ``Portal`` web application relative to the root of ``bundle``
    public let startDir: String
    
    /// The initial file to load in the Portal.
    public let index: String

    /// The `Bundle` that contains the web application.
    public var bundle: Bundle
    
    /// Any initial state required by the web application
    public var initialContext: JSObject
    
    /// The `LiveUpdateManager` responsible for locating the latest source for the web application
    public var liveUpdateManager: LiveUpdateManager

    /// The `LiveUpdate` configuration used to determine the location of updated application assets.
    public var liveUpdateConfig: LiveUpdate? = nil {
        didSet {
            guard let liveUpdateConfig = liveUpdateConfig else { return }
            try? liveUpdateManager.add(liveUpdateConfig)
        }
    }
    
    var pluginRegistrationMode: PluginRegistrationMode
    
    /// Creates an instance of ``Portal``
    /// - Parameters:
    ///   - name: The name of the portal, must be unique.
    ///   - startDir: The starting directory of the ``Portal`` relative to the root of ``bundle``.
    ///     If `nil`, the portal name is used as the starting directory. Defaults to `nil`.
    ///   - index: The initial file to load in the Portal. Defaults to `index.html`.
    ///   - bundle: The `Bundle` that contains the web application. Defaults to `Bundle.main`.
    ///   - initialContext: Any initial state required by the web application. Defaults to `[:]`.
    ///   - liveUpdateManager: The `LiveUpdateManager` responsible for locating the source source for the web application. Defaults to `LiveUpdateManager.shared`.
    ///   - liveUpdateConfig: The `LiveUpdate` configuration used to determine to location of updated application assets. Defaults to `nil`.
    public init(
        name: String,
        startDir: String? = nil,
        index: String = "index.html",
        bundle: Bundle = .main,
        initialContext: JSObject = [:],
        pluginRegistrationMode: PluginRegistrationMode = .automatic,
        liveUpdateManager: LiveUpdateManager = .shared,
        liveUpdateConfig: LiveUpdate? = nil
    ) {
        self.name = name
        self.startDir = startDir ?? name
        self.index = index
        self.initialContext = initialContext
        self.bundle = bundle
        self.pluginRegistrationMode = pluginRegistrationMode
        self.liveUpdateManager = liveUpdateManager
        self.liveUpdateConfig = liveUpdateConfig
        if let liveUpdateConfig = liveUpdateConfig {
            try? liveUpdateManager.add(liveUpdateConfig)
        }
    }
}

extension Portal {
    public func adding(_ plugins: [Plugin]) -> Portal {
        var copy = self
        switch copy.pluginRegistrationMode {
        case .automatic:
            copy.pluginRegistrationMode = .manual(plugins)
        case .manual(var existingPlugins):
            existingPlugins.append(contentsOf: plugins)
            copy.pluginRegistrationMode = .manual(existingPlugins)
        }
        return copy
    }
    
    public func adding(_ plugin: Plugin) -> Portal {
        adding([plugin])
    }
    
    public func adding(_ plugin: CAPPlugin) -> Portal {
        adding([.instance(plugin)])
    }
    
    public func adding(_ pluginType: CAPPlugin.Type) -> Portal {
        adding([.type(pluginType)])
    }
    
    public func adding(_ plugins: [CAPPlugin]) -> Portal {
        adding(plugins.map(Plugin.instance))
    }
    
    public func adding(_ pluginTypes: [CAPPlugin.Type]) -> Portal {
        adding(pluginTypes.map(Plugin.type))
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

extension Portal {
    public enum PluginRegistrationMode {
        case automatic
        case manual([Plugin])
    }
    
    public enum Plugin {
        case type(CAPPlugin.Type)
        case instance(CAPPlugin)
    }
}

extension Portal.PluginRegistrationMode {
    var isAutomatic: Bool {
        switch self {
        case .automatic:
            return true
        default:
            return false
        }
    }
}

/// The Objective-C representation of ``Portal``. If using Swift, using ``Portal`` is preferred.
@objc public class IONPortal: NSObject {
    internal var portal: Portal
    
    /// The name of the portal
    @objc public var name: String { portal.name }
    
    /// The `Bundle` that contains the web application.
    @objc public var bundle: Bundle {
        get { portal.bundle }
        set { portal.bundle = newValue }
    }
    
    /// The root directory of the ``IONPortal`` relative to root of the `Bundle`
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
            guard let newValue = JSTypes.coerceDictionaryToJSObject(newValue) else { return }
            portal.initialContext = newValue
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
    /// Creates an instance of ``IONPortal``
    /// - Parameters:
    ///   - name: The name of the portal, must be unique.
    ///   - startDir: The starting directory of the ``Portal`` relative to the root of ``bundle``.
    ///     If `nil`, the portal name is used as the starting directory.
    ///   - initialContext: Any initial state required by the web application. Defaults to `[:]`.
    @objc public convenience init(name: String, startDir: String?, initialContext: [String: Any]?) {
        let portal = Portal(
            name: name,
            startDir: startDir,
            initialContext: initialContext.flatMap { JSTypes.coerceDictionaryToJSObject($0) } ?? [:],
            liveUpdateConfig: nil
        )
        
        self.init(portal: portal)
    }
    
    /// Creates an instance of ``IONPortal``
    /// - Parameters:
    ///   - name: The name of the portal, must be unique.
    ///   - startDir: The starting directory of the ``Portal`` relative to the root of the ``bundle``.
    ///     If `nil`, the portal name is used as the starting directory.
    ///   - bundle: The `Bundle` that contains the web application.
    ///   - initialContext: Any initial state required by the web application. Defaults to `[:]`.
    @objc public convenience init(name: String, startDir: String?, bundle: Bundle, initialContext: [String: Any]?) {
        self.init(name: name, startDir: startDir, initialContext: initialContext)
        self.bundle = bundle
    }
}
