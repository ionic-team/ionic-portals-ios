//
//  PortalUIWebView.swift
//  IonicPortals
//
//  Created by Dan Giralté on 1/24/22.
//

import SwiftUI
import Capacitor

/// A SwiftUI View to display ``Portal`` content
public struct PortalView: UIViewRepresentable {
    private let portal: Portal
    private let onBridgeAvailable: (CAPBridgeProtocol) -> Void
    
    /// Creates an instance of ``PortalView``
    /// - Parameters:
    ///   - portal: The ``Portal`` to render.
    ///   - onBridgeAvailable: A callback to access the CapacitorBridge if needed. Defaults to a no-op.
    public init(portal: Portal, onBridgeAvailable: @escaping (CAPBridgeProtocol) -> Void = { _ in }) {
        self.portal = portal
        self.onBridgeAvailable = onBridgeAvailable
    }
    
    public func makeUIView(context: Context) -> PortalUIView {
        let webView = PortalUIView(portal: portal)
        onBridgeAvailable(webView.bridge)
        return webView
    }
    
    // Nothing to do here since there is no state to manage
    public func updateUIView(_ uiView: PortalUIView, context: Context) {}
}
