//
//  WebPerformanceReporter.swift
//  
//
//  Created by Steven Sherry on 1/6/23.
//

import Capacitor

/// A plugin to handle web performance metrics reporting from web applications
/// embedded in a ``PortalUIView`` or ``PortalView``
public class WebVitalsPlugin: CAPInstancePlugin, CAPBridgedPlugin {
    public let jsName = "WebVitals"
    public let identifier = "WebVitalsPlugin"
    public let pluginMethods: [CAPPluginMethod] = []

    /// Creates an instance of ``WebPerformanceReporter``
    /// - Parameter onFirstContentfulPaint: A closure that handles the First Contentful Paint metric.
    private let onFirstContentfulPaint: (_ portalName: String, _ duration: Double) -> Void

    // Built with the following:
    // web-vitals@3.1.0
    // esbuild@0.15.18
    //
    // Original script contents:
    // ```
    // import { onFCP } from "web-vitals";
    // onFCP(report => window.webkit.messageHandlers.vitals.postMessage({ name: report.name, value: report.value, portalName: window.portalInitialContext?.name });
    // ```
    //
    // Build command:
    // esbuild ./index.js --bundle --minify --tree-shaking=true --platform=browser --outfile=dist/index.js
    private let handlerScriptSource = #"""
    (()=>{var m=-1,h=function(e){addEventListener("pageshow",function(t){t.persisted&&(m=t.timeStamp,e(t))},!0)},g=function(){return window.performance&&performance.getEntriesByType&&performance.getEntriesByType("navigation")[0]},y=function(){var e=g();return e&&e.activationStart||0},d=function(e,t){var n=g(),i="navigate";return m>=0?i="back-forward-cache":n&&(i=document.prerendering||y()>0?"prerender":document.wasDiscarded?"restore":n.type.replace(/_/g,"-")),{name:e,value:t===void 0?-1:t,rating:"good",delta:0,entries:[],id:"v3-".concat(Date.now(),"-").concat(Math.floor(8999999999999*Math.random())+1e12),navigationType:i}},E=function(e,t,n){try{if(PerformanceObserver.supportedEntryTypes.includes(e)){var i=new PerformanceObserver(function(a){Promise.resolve().then(function(){t(a.getEntries())})});return i.observe(Object.assign({type:e,buffered:!0},n||{})),i}}catch{}};var l=function(e,t,n,i){var a,r;return function(s){t.value>=0&&(s||i)&&((r=t.value-(a||0))||a===void 0)&&(a=t.value,t.delta=r,t.rating=function(c,o){return c>o[1]?"poor":c>o[0]?"needs-improvement":"good"}(t.value,n),e(t))}},C=function(e){requestAnimationFrame(function(){return requestAnimationFrame(function(){return e()})})},L=function(e){document.prerendering?addEventListener("prerenderingchange",function(){return e()},!0):e()},u=-1,v=function(){return document.visibilityState!=="hidden"||document.prerendering?1/0:0},f=function(e){document.visibilityState==="hidden"&&u>-1&&(u=e.type==="visibilitychange"?e.timeStamp:0,w())},p=function(){addEventListener("visibilitychange",f,!0),addEventListener("prerenderingchange",f,!0)},w=function(){removeEventListener("visibilitychange",f,!0),removeEventListener("prerenderingchange",f,!0)},b=function(){return u<0&&(u=v(),p(),h(function(){setTimeout(function(){u=v(),p()},0)})),{get firstHiddenTime(){return u}}},T=function(e,t){t=t||{},L(function(){var n,i=[1800,3e3],a=b(),r=d("FCP"),s=E("paint",function(c){c.forEach(function(o){o.name==="first-contentful-paint"&&(s.disconnect(),o.startTime<a.firstHiddenTime&&(r.value=Math.max(o.startTime-y(),0),r.entries.push(o),n(!0)))})});s&&(n=l(e,r,i,t.reportAllChanges),h(function(c){r=d("FCP"),n=l(e,r,i,t.reportAllChanges),C(function(){r.value=performance.now()-c.timeStamp,n(!0)})}))})};var S=new Date;var I=1/0;T(e=>window.webkit.messageHandlers.vitals.postMessage({name:e.name,value:e.value,portalName:window.portalInitialContext?.name}));})();
    """#
    
    public init(_ onFirstContentfulPaint: @escaping (_ portalName: String, _ duration: Double) -> Void) {
        self.onFirstContentfulPaint = onFirstContentfulPaint
        super.init()
    }
    
    public override func load() {
        guard let contentController = bridge?.webView?.configuration.userContentController else { return }

        let handlerScript = WKUserScript(
            source: handlerScriptSource,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )

        contentController.add(PerformanceHandler(onFirstContentfulPaint: onFirstContentfulPaint), name: "vitals")
        contentController.addUserScript(handlerScript)
    }
    
    deinit {
        bridge?.webView?.configuration.userContentController.removeScriptMessageHandler(forName: "vitals")
    }
}

private class PerformanceHandler: NSObject, WKScriptMessageHandler {
    let onFirstContentfulPaint: (_ portalName: String, _ duration: Double) -> Void

    init(onFirstContentfulPaint: @escaping (String, Double) -> Void) {
        self.onFirstContentfulPaint = onFirstContentfulPaint
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let portalName = body["portalName"] as? String,
              let name = body["name"] as? String,
              let value = body["value"] as? Double
        else { return }

        switch name {
        case "FCP":
            onFirstContentfulPaint(portalName, value)
        default:
            return
        }
    }
}
