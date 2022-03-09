//
//  PortalView.swift
//  IonicPortals
//
//  Created by Dan Giralté on 1/24/22.
//

import SwiftUI
import Capacitor

public struct PortalView: UIViewRepresentable {
    let portal: Portal
    var onBridgeAvailable: (CAPBridgeProtocol) -> Void

    public init(_ portal: Portal, onBridgeAvailable: @escaping (CAPBridgeProtocol) -> Void) {
        self.portal = portal
        self.onBridgeAvailable = onBridgeAvailable
    }
    
    public func makeUIView(context: Context) -> PortalWebView {
        let webView = PortalWebView(portal: portal)
        onBridgeAvailable(webView.bridge)
        return webView
    }
    
    // Nothing to do here since there is no state to manage
    public func updateUIView(_ uiView: PortalWebView, context: Context) {}
}
