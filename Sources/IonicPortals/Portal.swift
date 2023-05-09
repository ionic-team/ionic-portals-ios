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
    
    /// Any Capacitor plugins to load on the ``Portal``
    public var plugins: [Plugin]
    
    /// The `LiveUpdateManager` responsible for locating the latest source for the web application
    public var liveUpdateManager: LiveUpdateManager

    /// The `LiveUpdate` configuration used to determine the location of updated application assets.
    public var liveUpdateConfig: LiveUpdate? = nil {
        didSet {
            guard let liveUpdateConfig = liveUpdateConfig else { return }
            try? liveUpdateManager.add(liveUpdateConfig)
        }
    }

    /// Assets needed to be shared between web and native
    public var assetMaps: [AssetMap]

    /// The ``WebPerformanceReporter`` to handle metric events from the web application
    public var performanceReporter: WebPerformanceReporter?

    /// Creates an instance of ``Portal``
    /// - Parameters:
    ///   - name: The name of the portal, must be unique.
    ///   - startDir: The starting directory of the ``Portal`` relative to the root of ``bundle``.
    ///     If `nil`, the portal name is used as the starting directory. Defaults to `nil`.
    ///   - index: The initial file to load in the Portal. Defaults to `index.html`.
    ///   - bundle: The `Bundle` that contains the web application. Defaults to `Bundle.main`.
    ///   - plugins: Any ``Plugin``s to load. Defautls to `[]`.
    ///   - initialContext: Any initial state required by the web application. Defaults to `[:]`.
    ///   - assetMaps: Any ``AssetMap``s needed to share assets with the ``Portal``. Defaults to `[]`.
    ///   - liveUpdateManager: The `LiveUpdateManager` responsible for locating the source source for the web application. Defaults to `LiveUpdateManager.shared`.
    ///   - liveUpdateConfig: The `LiveUpdate` configuration used to determine to location of updated application assets. Defaults to `nil`.
    ///   - performanceReport: The ``WebPerformanceReporter`` to handle metric events from the web application. Defaults to `nil`.
    public init(
        name: String,
        startDir: String? = nil,
        index: String = "index.html",
        bundle: Bundle = .main,
        initialContext: JSObject = [:],
        assetMaps: [AssetMap] = [],
        plugins: [Plugin] = [],
        liveUpdateManager: LiveUpdateManager = .shared,
        liveUpdateConfig: LiveUpdate? = nil,
        performanceReporter: WebPerformanceReporter? = nil
    ) {
        self.name = name
        self.startDir = startDir ?? name
        self.index = index
        self.initialContext = initialContext
        self.bundle = bundle
        self.plugins = plugins
        self.liveUpdateManager = liveUpdateManager
        self.liveUpdateConfig = liveUpdateConfig
        self.performanceReporter = performanceReporter
        if let liveUpdateConfig = liveUpdateConfig {
            try? liveUpdateManager.add(liveUpdateConfig)
        }
        self.assetMaps = assetMaps
    }
}

extension Portal {
    
    /// Returns a new ``Portal`` with the plugins added to ``plugins``.
    /// - Parameter plugins: The plugins to manually register
    /// - Returns: A new ``Portal`` with the plugins added to ``plugins``
    public func adding(_ plugins: [Plugin]) -> Portal {
        var copy = self
        copy.plugins.append(contentsOf: plugins)
        return copy
    }
    
    /// Returns a new ``Portal`` with the plugin added to ``plugins``.
    /// - Parameter plugin: The plugin to manually register
    /// - Returns: A new ``Portal`` with the plugin added to ``plugins``
    public func adding(_ plugin: Plugin) -> Portal {
        adding([plugin])
    }
    
    /// Returns a new ``Portal`` with the plugin instance added to ``plugins``.
    /// - Parameter plugin: The plugin instance to manually register
    /// - Returns: A new ``Portal`` with the plugin instance added to ``plugins``
    public func adding(_ plugin: CAPPlugin) -> Portal {
        adding([.instance(plugin)])
    }
    
    /// Returns a new ``Portal`` with the plugin type added to ``plugins``.
    /// - Parameter pluginType: The plugin type to manually register
    /// - Returns: A new ``Portal`` with the plugin type added to ``plugins``
    public func adding(_ pluginType: CAPPlugin.Type) -> Portal {
        adding([.type(pluginType)])
    }
    
    /// Returns a new ``Portal`` with the plugin instances added to ``plugins``.
    /// - Parameter plugins: The plugin instances to manually register
    /// - Returns: A new ``Portal`` with the plugin instances added to ``plugins``
    public func adding(_ plugins: [CAPPlugin]) -> Portal {
        adding(plugins.map(Plugin.instance))
    }
    
    /// Returns a new ``Portal`` with the plugin types added to ``plugins``.
    /// - Parameter pluginTypes: The plugins types to manually register
    /// - Returns: A new ``Portal`` with the plugin instances added to ``plugins``
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
    /// The two ways of registering Capacitor Plugins with a Portal.
    ///
    /// A ``type(_:)`` is initialized by the bridge on the users behalf.
    /// An ``instance(_:)`` is given directly to the bridge.
    public enum Plugin {
        /// Allow the Capacitor runtime to initialize the plugin on your behalf.
        /// > Note: If you are using plugin from the official or community plugins
        /// this is usually the best option
        case type(CAPPlugin.Type)
        /// Registers the instance with the Capacitor runtime.
        /// > Note: This is usually a good option if you have custom plugins
        /// you have written for your application that need to be passed
        /// via initialization or otherwise having the instance beforehand is needed
        /// before providing it to the capacitor bridge. The ``PortalsPlugin`` ``PortalsPlugin/init(pubsub:)``
        /// initializer is an example of a scenario where you would need to use ``instance(_:)``.
        case instance(CAPPlugin)
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
