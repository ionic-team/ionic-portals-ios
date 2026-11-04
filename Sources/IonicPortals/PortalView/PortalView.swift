//
//  PortalView.swift
//  IonicPortals
//
//  Created by Dan Giralté on 1/24/22.
//

import SwiftUI
import Capacitor

/// A SwiftUI View to display ``Portal`` content
///
/// The underlying ``PortalUIView`` and its bridge are created once: a different ``Portal`` passed in
/// later is ignored, and `onBridgeAvailable` is only called when the view is created. To display a
/// different portal, give the view an identity that changes whenever the portal or its configuration
/// does, so SwiftUI recreates it:
///
/// ```swift
/// PortalView(portal: selectedPortal)
///     .id(selectedPortal.name)
/// ```
public struct PortalView: UIViewRepresentable {
    private let portal: Portal
    private let onBridgeAvailable: (CapacitorBridge) -> Void

    /// Creates an instance of ``PortalView``
    /// - Parameters:
    ///   - portal: The ``Portal`` to render.
    ///   - onBridgeAvailable: A callback to access the CapacitorBridge if needed. Defaults to a no-op.
    public init(portal: Portal, onBridgeAvailable: @escaping (CapacitorBridge) -> Void = { _ in }) {
        self.portal = portal
        self.onBridgeAvailable = onBridgeAvailable
    }

    public func makeUIView(context: Context) -> PortalUIView {
        let view = PortalUIView(portal: portal)
        onBridgeAvailable(view.bridge)
        return view
    }

    // Portal changes are not applied; see the type documentation
    public func updateUIView(_ uiView: PortalUIView, context: Context) {}
}
