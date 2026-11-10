import Foundation
import WebKit
import UIKit
import Capacitor

/// A UIKit UIView to display ``Portal`` content
///
/// To pass deep links to plugins in a portal, such as `@capacitor/app`'s `appUrlOpen` event, forward
/// them with `ApplicationDelegateProxy` or with `SceneDelegateProxy`'s `scene(_:openURLContexts:)` and
/// `scene(_:continue:)`. `SceneDelegateProxy`'s `handle(openURL:)`, `handle(userActivity:)` and
/// `scene(_:willConnectTo:options:)` hold links until a `CAPBridgeViewController` appears, so in an
/// app that only shows portals they're never delivered:
///
/// ```swift
/// .onOpenURL { url in
///     _ = ApplicationDelegateProxy.shared.application(UIApplication.shared, open: url)
/// }
/// ```
@objc(IONPortalUIView)
public class PortalUIView: UIView {
    private let portal: Portal
    private var liveUpdatePath: URL?
    private let configuration: InstanceConfiguration
    private let assetHandler: WebViewAssetHandler
    private let delegationHandler = WebViewDelegationHandler()
    private let webView: WKWebView

    @objc
    public private(set) lazy var bridge = CapacitorBridge(
        with: configuration,
        delegate: self,
        assetHandler: assetHandler,
        delegationHandler: delegationHandler,
        autoRegisterPlugins: false
    )

    /// Creates an instance of ``PortalUIView``
    /// - Parameter portal: The ``Portal`` to render.
    required public init(portal: Portal) {
        self.portal = portal
        liveUpdatePath = portal.liveUpdateDirectory
        let descriptor = portal.instanceDescriptor(liveUpdateDirectory: liveUpdatePath)
        configuration = InstanceConfiguration(with: descriptor, isDebug: CapacitorBridge.isDevEnvironment)
        CAPLog.enableLogging = configuration.loggingEnabled
        CapacitorWebViewSetup.logWarnings(for: descriptor)

        assetHandler = WebViewAssetHandler(router: PortalRouter(index: portal.index, assetMaps: portal.assetMaps))
        assetHandler.setAssetPath(configuration.appLocation.path)
        assetHandler.setServerUrl(configuration.serverURL)

        delegationHandler.contentController.addUserScript(WKUserScript(
            source: portal.initialContextScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))
        webView = CapacitorWebViewSetup.makeWebView(
            with: configuration,
            assetHandler: assetHandler,
            delegationHandler: delegationHandler
        )

        super.init(frame: .zero)

        backgroundColor = webView.scrollView.backgroundColor
        addSubview(webView)

        guard FileManager.default.fileExists(atPath: bridge.config.appStartFileURL.path) else {
            CapacitorWebViewSetup.printLoadError(startFile: bridge.config.appStartFileURL)
            return
        }

        registerPlugins()

        let url = bridge.config.appStartServerURL
        CAPLog.print("⚡️  Loading app at \(url.absoluteString)")
        bridge.webViewDelegationHandler.willLoadWebview(webView)
        _ = webView.load(URLRequest(url: url))
    }

    /// Creates an instance of ``PortalUIView``
    /// - Parameter portal: The ``IONPortal`` to render.
    @objc public convenience init(portal: IONPortal) {
        self.init(portal: portal.portal)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // WebKit moves the web view out for element fullscreen and back on exit, which drops any constraints on it
    public override func layoutSubviews() {
        super.layoutSubviews()
        webView.frame = bounds
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
}

extension PortalUIView {
    public func setServerBasePath(path: String) {
        // The bridge also ignores a missing path, but checking here skips the reload as well
        guard FileManager.default.fileExists(atPath: path) else { return }
        bridge.setServerBasePath(path)

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            _ = webView.load(URLRequest(url: bridge.config.serverURL))
        }
    }

    /// Reloads the underlying `WKWebView`
    @objc public func reload() {
        if let latestAppPath = portal.liveUpdateDirectory, latestAppPath.path != liveUpdatePath?.path {
            liveUpdatePath = latestAppPath
            return setServerBasePath(path: latestAppPath.path)
        }

        DispatchQueue.main.async { [weak self] in
            self?.webView.reload()
        }
    }
}

extension PortalUIView: CAPBridgeDelegate {
    public var bridgedWebView: WKWebView? {
        return webView
    }

    public var bridgedViewController: UIViewController? {
        var object = self.next
        while !(object is UIViewController) && object != nil {
            object = object?.next
        }
        return object as? UIViewController
    }
}
