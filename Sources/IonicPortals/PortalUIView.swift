import Foundation
import WebKit
import UIKit
import Capacitor
import IonicLiveUpdates
import SwiftUI

/// A UIKit UIView to display ``Portal`` content
@objc(IONPortalUIView)
public class PortalUIView: UIView {
    private lazy var webView = InternalCapWebView(portal: portal, liveUpdatePath: liveUpdatePath)
    private let portal: Portal
    private var liveUpdatePath: URL?
    @objc public var bridge: CAPBridgeProtocol {
        webView.bridge
    }
    
    /// Creates an instance of ``PortalUIView``
    /// - Parameter portal: The ``Portal`` to render.
    public init(portal: Portal) {
        self.portal = portal
        super.init(frame: .zero)
        initView()
    }

    /// Creates an instance of ``PortalUIView``
    /// - Parameter portal: The ``IONPortal`` to render.
    @objc public convenience init(portal: IONPortal) {
        self.init(portal: portal.portal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initView () {
        if PortalsRegistrationManager.shared.isRegistered {
            if let liveUpdateConfig = portal.liveUpdateConfig {
                self.liveUpdatePath = try? portal.liveUpdateManager.latestAppDirectory(for: liveUpdateConfig.appId)
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
    
    /// Reloads the underlying `WKWebView`
    @objc public func reload() {
        if let liveUpdate = portal.liveUpdateConfig,
           let latestAppPath = try? portal.liveUpdateManager.latestAppDirectory(for: liveUpdate.appId),
           liveUpdatePath == nil || liveUpdatePath?.path != latestAppPath.path {
            liveUpdatePath = latestAppPath
            return webView.setServerBasePath(path: latestAppPath.path)
        }

        DispatchQueue.main.async { [weak self] in
            self?.bridge.webView?.reload()
        }
    }
    
    final class InternalCapWebView: CAPWebView {
        private var portal: Portal
        private var liveUpdatePath: URL?

        override var router: Router { PortalRouter(portal: portal) }

        init(portal: Portal, liveUpdatePath: URL?) {
            self.portal = portal
            self.liveUpdatePath = liveUpdatePath
            super.init(autoRegisterPlugins: false)
        }

        override func capacitorDidLoad() {
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
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func createInstanceDescriptor() -> InstanceDescriptor {
            let bundleURL = portal.bundle.url(forResource: portal.startDir, withExtension: nil)

            #if DEBUG
            if let debugConfigUrl = portal.devConfig?.capacitorConfig.url {
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
        
        override func instanceDescriptor() -> InstanceDescriptor {
            let descriptor = createInstanceDescriptor()
            portal.descriptorConfiguration.forEach { $0(descriptor) }
            #if DEBUG
            if portal.devConfig?.server.url != nil {
                descriptor.serverURL = portal.devConfig?.server.url?.absoluteString
                // This allows for not having any files on disk during dev
                if !FileManager.default.fileExists(atPath: descriptor.appLocation.path) {
                    descriptor.appLocation = Bundle.main.bundleURL
                }
            }
            #endif
            return descriptor
        }
        
        override func loadInitialContext(_ userContentViewController: WKUserContentController) {
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

