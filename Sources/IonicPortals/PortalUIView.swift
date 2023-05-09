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
        
        override func instanceDescriptor() -> InstanceDescriptor {
            let bundleURL = portal.bundle.url(forResource: portal.startDir, withExtension: nil)
            
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
 
            if let reporter = portal.performanceReporter {
                // Built with the following:
                // web-vitals@3.1.0
                // esbuild@0.15.18
                //
                // Original script contents:
                // ```
                // import { onFCP } from "web-vitals";
                // onFCP(report => window.webkit.messageHandlers.vitals.postMessage({ name: report.name, value: report.value });
                // ```
                //
                // Build command:
                // esbuild ./index.js --bundle --minify --tree-shaking=true --platform=browser --outfile=dist/index.js
                let handlerScriptSource = #"""
                (()=>{var m=-1,h=function(e){addEventListener("pageshow",function(t){t.persisted&&(m=t.timeStamp,e(t))},!0)},g=function(){return window.performance&&performance.getEntriesByType&&performance.getEntriesByType("navigation")[0]},y=function(){var e=g();return e&&e.activationStart||0},d=function(e,t){var n=g(),i="navigate";return m>=0?i="back-forward-cache":n&&(i=document.prerendering||y()>0?"prerender":document.wasDiscarded?"restore":n.type.replace(/_/g,"-")),{name:e,value:t===void 0?-1:t,rating:"good",delta:0,entries:[],id:"v3-".concat(Date.now(),"-").concat(Math.floor(8999999999999*Math.random())+1e12),navigationType:i}},E=function(e,t,n){try{if(PerformanceObserver.supportedEntryTypes.includes(e)){var i=new PerformanceObserver(function(a){Promise.resolve().then(function(){t(a.getEntries())})});return i.observe(Object.assign({type:e,buffered:!0},n||{})),i}}catch{}};var l=function(e,t,n,i){var a,r;return function(s){t.value>=0&&(s||i)&&((r=t.value-(a||0))||a===void 0)&&(a=t.value,t.delta=r,t.rating=function(c,o){return c>o[1]?"poor":c>o[0]?"needs-improvement":"good"}(t.value,n),e(t))}},C=function(e){requestAnimationFrame(function(){return requestAnimationFrame(function(){return e()})})},L=function(e){document.prerendering?addEventListener("prerenderingchange",function(){return e()},!0):e()},u=-1,v=function(){return document.visibilityState!=="hidden"||document.prerendering?1/0:0},f=function(e){document.visibilityState==="hidden"&&u>-1&&(u=e.type==="visibilitychange"?e.timeStamp:0,w())},p=function(){addEventListener("visibilitychange",f,!0),addEventListener("prerenderingchange",f,!0)},w=function(){removeEventListener("visibilitychange",f,!0),removeEventListener("prerenderingchange",f,!0)},b=function(){return u<0&&(u=v(),p(),h(function(){setTimeout(function(){u=v(),p()},0)})),{get firstHiddenTime(){return u}}},T=function(e,t){t=t||{},L(function(){var n,i=[1800,3e3],a=b(),r=d("FCP"),s=E("paint",function(c){c.forEach(function(o){o.name==="first-contentful-paint"&&(s.disconnect(),o.startTime<a.firstHiddenTime&&(r.value=Math.max(o.startTime-y(),0),r.entries.push(o),n(!0)))})});s&&(n=l(e,r,i,t.reportAllChanges),h(function(c){r=d("FCP"),n=l(e,r,i,t.reportAllChanges),C(function(){r.value=performance.now()-c.timeStamp,n(!0)})}))})};var S=new Date;var P=1/0;T(e=>window.webkit.messageHandlers.vitals.postMessage({name:e.name,value:e.value}));})();
                """#

                let handlerScript = WKUserScript(
                    source: handlerScriptSource,
                    injectionTime: .atDocumentStart,
                    forMainFrameOnly: true
                )

                userContentViewController.add(PerformanceHandler(portalName: portal.name, performanceReporter: reporter), name: "vitals")
                userContentViewController.addUserScript(handlerScript)
            }
        }
    }
    
}

private class PerformanceHandler: NSObject, WKScriptMessageHandler {
    let performanceReporter: WebPerformanceReporter
    let portalName: String

    init(portalName: String, performanceReporter: WebPerformanceReporter) {
        self.performanceReporter = performanceReporter
        self.portalName = portalName
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let name = body["name"] as? String,
              let value = body["value"] as? Double
        else { return }

        switch name {
        case "FCP":
            performanceReporter.onFirstContentfulPaint(portalName, value)
        default:
            return
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

