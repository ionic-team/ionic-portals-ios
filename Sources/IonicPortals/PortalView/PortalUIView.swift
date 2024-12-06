import Foundation
import WebKit
import UIKit
import Capacitor
import IonicLiveUpdates
import SwiftUI

/// A UIKit UIView to display ``Portal`` content
@objc(IONPortalUIView)
public class PortalUIView: UIView {
    // MARK: Capacitor
    private lazy var webView: WKWebView = createWebView(
        with: configuration,
        assetHandler: assetHandler,
        delegationHandler: delegationHandler
    )

    private lazy var configDescriptor = instanceDescriptor()
    private lazy var configuration = InstanceConfiguration(with: configDescriptor, isDebug: CapacitorBridge.isDevEnvironment)
    private lazy var delegationHandler = WebViewDelegationHandler()

    @objc
    public private(set) lazy var bridge = CapacitorBridge(
        with: configuration,
        delegate: self,
        cordovaConfiguration: configDescriptor.cordovaConfiguration,
        assetHandler: assetHandler,
        delegationHandler: delegationHandler,
        autoRegisterPlugins: false
    )

    private lazy var assetHandler: WebViewAssetHandler = {
        let handler = WebViewAssetHandler(router: router)
        handler.setAssetPath(configuration.appLocation.path)
        handler.setServerUrl(configuration.serverURL)
        return handler
    }()

    private lazy var router = PortalRouter(portal: portal)
    

    #if DEBUG
    private lazy var devConfiguration = DevConfiguration(baseName: portal.name)
    #endif

    private let portal: Portal
    private var liveUpdatePath: URL?

    /// Creates an instance of ``PortalUIView``
    /// - Parameter portal: The ``Portal`` to render.
    required public init(portal: Portal) {
        self.portal = portal
        super.init(frame: .zero)
        initView()
        setup()
    }

    /// Creates an instance of ``PortalUIView``
    /// - Parameter portal: The ``IONPortal`` to render.
    @objc public convenience init(portal: IONPortal) {
        self.init(portal: portal.portal)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        CAPLog.enableLogging = configuration.loggingEnabled
        logWarnings(for: configDescriptor)
        
        guard FileManager.default.fileExists(atPath: bridge.config.appStartFileURL.path) else {
            printLoadError()
            return
        }

        initView()
        registerPlugins()

        let url = bridge.config.appStartServerURL
        CAPLog.print("⚡️  Loading app at \(url.absoluteString)")
        bridge.webViewDelegationHandler.willLoadWebview(webView)
        _ = webView.load(URLRequest(url: url))
    }

    private func initView () {
        if PortalsRegistrationManager.shared.isRegistered {
            if let liveUpdateConfig = portal.liveUpdateConfig {
                self.liveUpdatePath = portal.liveUpdateManager.latestAppDirectory(for: liveUpdateConfig.appId)
            }

            addPinnedSubview(webView)
        } else {
            let showRegistrationError = PortalsRegistrationManager.shared.registrationState == .error
            let _view = Unregistered(shouldShowRegistrationError: showRegistrationError)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .background(Color.portalBlue)

            let view = UIHostingController(rootView: _view).view

            addPinnedSubview(view!)
        }
    }

    private func registerPlugins() {
        bridge.registerPluginInstance(PortalsPlugin())

        portal.plugins.forEach { plugin in
            switch plugin {
            case .instance(let instance):
                bridge.registerPluginInstance(instance)
            case .type(let pluginType):
                bridge.registerPluginType(pluginType)
            }
        }
    }

    private func createWebView(with configuration: InstanceConfiguration, assetHandler: WebViewAssetHandler, delegationHandler: WebViewDelegationHandler) -> WKWebView {
        // set the cookie policy
        HTTPCookieStorage.shared.cookieAcceptPolicy = HTTPCookie.AcceptPolicy.always
        // setup the web view configuration
        let webViewConfig = _webViewConfiguration(for: configuration)
        webViewConfig.setURLSchemeHandler(assetHandler, forURLScheme: configuration.localURL.scheme ?? InstanceDescriptorDefaults.scheme)
        webViewConfig.userContentController = delegationHandler.contentController
        // create the web view and set its properties
        loadInitialContext(webViewConfig.userContentController)
        let webView = WKWebView(frame: .zero, configuration: webViewConfig)
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = configuration.contentInsetAdjustmentBehavior
        webView.allowsLinkPreview = configuration.allowLinkPreviews
        webView.scrollView.isScrollEnabled = configuration.scrollingEnabled

        if let overrideUserAgent = configuration.overridenUserAgentString {
            webView.customUserAgent = overrideUserAgent
        }

        if let backgroundColor = configuration.backgroundColor {
            self.backgroundColor = backgroundColor
            webView.backgroundColor = backgroundColor
            webView.scrollView.backgroundColor = backgroundColor
        } else {
            // Use the system background colors if background is not set by user
            self.backgroundColor = UIColor.systemBackground
            webView.backgroundColor = UIColor.systemBackground
            webView.scrollView.backgroundColor = UIColor.systemBackground
        }

        // set our delegates
        webView.uiDelegate = delegationHandler
        webView.navigationDelegate = delegationHandler
        return webView
    }

    private func _webViewConfiguration(for instanceConfiguration: InstanceConfiguration) -> WKWebViewConfiguration {
        let webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.websiteDataStore.httpCookieStore.add(CapacitorWKCookieObserver())
        webViewConfiguration.allowsInlineMediaPlayback = true
        webViewConfiguration.suppressesIncrementalRendering = false
        webViewConfiguration.allowsAirPlayForMediaPlayback = true
        webViewConfiguration.mediaTypesRequiringUserActionForPlayback = []

        if #available(iOS 14.0, *) {
            webViewConfiguration.limitsNavigationsToAppBoundDomains = instanceConfiguration.limitsNavigationsToAppBoundDomains
        }

        if let appendUserAgent = instanceConfiguration.appendedUserAgentString {
            if let appName = webViewConfiguration.applicationNameForUserAgent {
                webViewConfiguration.applicationNameForUserAgent = "\(appName)  \(appendUserAgent)"
            } else {
                webViewConfiguration.applicationNameForUserAgent = appendUserAgent
            }
        }

        if let preferredContentMode = instanceConfiguration.preferredContentMode {
            var mode = WKWebpagePreferences.ContentMode.recommended
            if preferredContentMode == "mobile" {
                mode = WKWebpagePreferences.ContentMode.mobile
            } else if preferredContentMode == "desktop" {
                mode = WKWebpagePreferences.ContentMode.desktop
            }
            webViewConfiguration.defaultWebpagePreferences.preferredContentMode = mode
        }

        return webViewConfiguration
    }

    private func createInstanceDescriptor() -> InstanceDescriptor {
        let bundleURL = portal.bundle.url(forResource: portal.startDir, withExtension: nil)

        #if DEBUG
        if portal.devModeEnabled, let debugConfigUrl = devConfiguration.capacitorConfig.url ?? DevConfiguration.default.capacitorConfig.url {
            return InstanceDescriptor(at: Bundle.main.bundleURL, configuration: debugConfigUrl, cordovaConfiguration: nil)
        }
        #endif

        guard let path = liveUpdatePath ?? bundleURL else {
            // DCG this should throw or something else
            return InstanceDescriptor()
        }

        var capConfigUrl = portal.bundle.url(forResource: "capacitor.config", withExtension: "json", subdirectory: portal.startDir)
        var cordovaConfigUrl = portal.bundle.url(forResource: "config", withExtension: "xml", subdirectory: portal.startDir)

        if let updatedCapConfig = liveUpdatePath?.appendingPathComponent("capacitor.config.json"),
           FileManager.default.fileExists(atPath: updatedCapConfig.path) {
            capConfigUrl = updatedCapConfig
        }

        if let updatedCordovaConfig = liveUpdatePath?.appendingPathComponent("config.xml"),
           FileManager.default.fileExists(atPath: updatedCordovaConfig.path) {
            cordovaConfigUrl = updatedCordovaConfig
        }


        let descriptor = InstanceDescriptor(at: path, configuration: capConfigUrl, cordovaConfiguration: cordovaConfigUrl)
        descriptor.handleApplicationNotifications = false
        return descriptor
    }

    private func instanceDescriptor() -> InstanceDescriptor {
        let descriptor = createInstanceDescriptor()
        portal.descriptorConfiguration.forEach { $0(descriptor) }

        #if DEBUG
        if portal.devModeEnabled, let serverUrl = devConfiguration.server.url ?? DevConfiguration.default.server.url {
            descriptor.serverURL = serverUrl.absoluteString
            // This allows for not having any files on disk during dev
            if !FileManager.default.fileExists(atPath: descriptor.appLocation.path) {
                descriptor.appLocation = Bundle.main.bundleURL
            }
        }
        #endif

        return descriptor
    }

    private func loadInitialContext(_ userContentViewController: WKUserContentController) {
        let portalInitialContext: String

        var initialContext: [String: Any] = ["name": portal.name]

        if portal.initialContext.isNotEmpty {
            initialContext["value"] = portal.initialContext
        }

        if portal.assetMaps.isNotEmpty {
            initialContext["assets"] = portal.assetMaps.reduce(into: [:]) { acc, next in
                acc[next.name] = next.virtualPath
            }
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: initialContext),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            portalInitialContext = jsonString
        } else {
            portalInitialContext = #"{ "name": "\#(portal.name)" }"#
        }

        let scriptSource = "window.portalInitialContext = " + portalInitialContext

        let userScript = WKUserScript(
            source: scriptSource,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )

        userContentViewController.addUserScript(userScript)
    }
    
    private func logWarnings(for descriptor: InstanceDescriptor) {
        if descriptor.warnings.contains(.missingAppDir) {
            CAPLog.print("⚡️  ERROR: Unable to find application directory at: \"\(descriptor.appLocation.absoluteString)\"!")
        }
        if descriptor.instanceType == .fixed {
            if descriptor.warnings.contains(.missingFile) {
                CAPLog.print("Unable to find capacitor.config.json, make sure it exists and run npx cap copy.")
            }
            if descriptor.warnings.contains(.invalidFile) {
                CAPLog.print("Unable to parse capacitor.config.json. Make sure it's valid JSON.")
            }
            if descriptor.warnings.contains(.missingCordovaFile) {
                CAPLog.print("Unable to find config.xml, make sure it exists and run npx cap copy.")
            }
            if descriptor.warnings.contains(.invalidCordovaFile) {
                CAPLog.print("Unable to parse config.xml. Make sure it's valid XML.")
            }
        }
    }
    
    private func printLoadError() {
        let fullStartPath = bridge.config.appStartFileURL.path

        CAPLog.print("⚡️  ERROR: Unable to load \(fullStartPath)")
        CAPLog.print("⚡️  This file is the root of your web app and must exist before")
        CAPLog.print("⚡️  Capacitor can run. Ensure you've run capacitor copy at least")
        CAPLog.print("⚡️  or, if embedding, that this directory exists as a resource directory.")
    }
}

extension PortalUIView {
    public func setServerBasePath(path: String) {
        let url = URL(fileURLWithPath: path, isDirectory: true)
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        bridge.config = bridge.config.updatingAppLocation(url)
        bridge.webViewAssetHandler.setAssetPath(url.path)

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            _ = webView.load(URLRequest(url: bridge.config.serverURL))
        }
    }
    /// Reloads the underlying `WKWebView`
    @objc public func reload() {
        if let liveUpdate = portal.liveUpdateConfig,
           let latestAppPath = portal.liveUpdateManager.latestAppDirectory(for: liveUpdate.appId),
           liveUpdatePath == nil || liveUpdatePath?.path != latestAppPath.path {
            liveUpdatePath = latestAppPath
            return setServerBasePath(path: latestAppPath.path)
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            bridge.webView?.reload()
        }
    }
}

extension PortalUIView: CAPBridgeDelegate {
    public var bridgedWebView: WKWebView? {
        return webView
    }

    public var bridgedViewController: UIViewController? {
        // search for the parent view controller
        var object = self.next
        while !(object is UIViewController) && object != nil {
            object = object?.next
        }
        return object as? UIViewController
    }
}

internal struct PortalRouter: Router {
    var portal: Portal
    var basePath: String = ""

    func route(for path: String) -> String {
        let pathUrl = URL(fileURLWithPath: path)
        // If there's no path extension it also means the path is empty or a SPA route
        if pathUrl.pathExtension.isEmpty {
            return basePath + "/\(portal.index)"
        }

        if let assetPath = portal
            .assetMaps
            .compactMap({ $0.path(for: path) })
            .first {

            return assetPath
        }

        return basePath + path
    }
}

extension Collection {
    var isNotEmpty: Bool { !isEmpty }
}

extension UIView {
    func constraintsPinned(to view: UIView) -> [NSLayoutConstraint] {
        return [
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
    }

    func addPinnedSubview(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate(view.constraintsPinned(to: self))
    }
}

