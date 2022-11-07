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
        
        override var router: Router { PortalRouter(index: portal.index) }

        init(portal: Portal, liveUpdatePath: URL?) {
            self.portal = portal
            self.liveUpdatePath = liveUpdatePath
            super.init()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func instanceDescriptor() -> InstanceDescriptor {
            let bundleURL = portal.bundle.url(forResource: portal.startDir, withExtension: nil)
            
            guard let path = liveUpdatePath ?? bundleURL else {
                // DCG this should throw or something else
                return InstanceDescriptor()
            }
            
            let capConfigUrl = portal.bundle.url(forResource: "capacitor.config", withExtension: "json", subdirectory: portal.startDir)
            let cordovaConfigUrl = portal.bundle.url(forResource: "config", withExtension: "xml", subdirectory: portal.startDir)
            
            let descriptor = InstanceDescriptor(at: path, configuration: capConfigUrl, cordovaConfiguration: cordovaConfigUrl)
            descriptor.handleApplicationNotifications = false
            return descriptor
        }
        
        override func loadInitialContext(_ userContentViewController: WKUserContentController) {
            let portalInitialContext: String
            
            if portal.initialContext.isNotEmpty,
                let jsonData = try? JSONSerialization.data(withJSONObject: portal.initialContext),
                let jsonString = String(data: jsonData, encoding: .utf8) {
                portalInitialContext = #"{ "name": "\#(portal.name)", "value": \#(jsonString) }"#
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
    let index: String
    var basePath: String = ""

    func route(for path: String) -> String {
        let pathUrl = URL(fileURLWithPath: path)
        // If there's no path extension it also means the path is empty or a SPA route
        if pathUrl.pathExtension.isEmpty {
            return basePath + "/\(index)"
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



