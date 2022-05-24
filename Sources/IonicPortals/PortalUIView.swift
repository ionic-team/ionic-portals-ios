import Foundation
import WebKit
import UIKit
import Capacitor
import IonicLiveUpdates
import SwiftUI

/// A UIKit UIView to display ``Portal`` content
@objc(IONPortalUIView)
public class PortalUIView: UIView {
    lazy var webView = InternalCapWebView(portal: portal, liveUpdatePath: liveUpdatePath)
    var portal: Portal
    var liveUpdatePath: URL? = nil
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
                self.liveUpdatePath = try? LiveUpdateManager.shared.latestAppDirectory(for: liveUpdateConfig.appId)
            }
            
            addPinnedSubview(webView)
        } else {
            let _view = Unregistered()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .background(Color.portalBlue)
            
            let view = UIHostingController(rootView: _view).view
            
            addPinnedSubview(view!)
        }
    }
    
    /// Reloads the underlying `WKWebView`
    @objc public func reload() {
        guard
            let liveUpdate = portal.liveUpdateConfig,
            let capViewController = bridge.viewController as? CAPBridgeViewController,
            let latestAppPath = try? LiveUpdateManager.shared.latestAppDirectory(for: liveUpdate.appId)
        else { return }

        if liveUpdatePath == nil || liveUpdatePath?.path != latestAppPath.path {
            liveUpdatePath = latestAppPath
            capViewController.setServerBasePath(path: liveUpdatePath!.path)
            return
        }

        // Reload the bridge to the existing start url
        bridge.webView?.reload()
    }
    
    class InternalCapWebView: CAPWebView {
        var portal: Portal
        var liveUpdatePath: URL? = nil

        init(portal: Portal, liveUpdatePath: URL?) {
            self.portal = portal
            self.liveUpdatePath = liveUpdatePath
            super.init()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func instanceDescriptor() -> InstanceDescriptor {
            let bundleURL = Bundle.main.url(forResource: self.portal.startDir, withExtension: nil)
            
            guard let path = self.liveUpdatePath ?? bundleURL else {
                // DCG this should throw or something else
                return InstanceDescriptor()
            }
            
            let capConfigUrl = Bundle.main.url(forResource: "capacitor.config", withExtension: "json", subdirectory: portal.startDir)
            let cordovaConfigUrl = Bundle.main.url(forResource: "config", withExtension: "xml", subdirectory: portal.startDir)
            
            let descriptor = InstanceDescriptor(at: path, configuration: capConfigUrl, cordovaConfiguration: cordovaConfigUrl)
            
            return descriptor
        }
        
        override func loadInitialContext(_ userContentViewController: WKUserContentController) {
            guard portal.initialContext.isNotEmpty, let jsonData = try? JSONSerialization.data(withJSONObject: portal.initialContext) else { return }
                
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            let portalInitialContext = #"{ "name": "\#(portal.name)", "value": \#(jsonString) }"#
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



