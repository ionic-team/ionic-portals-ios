import Foundation
import WebKit
import UIKit
import Capacitor

/// Mirrors the private web view setup in Capacitor's `CAPBridgeViewController`, which a `UIView` cannot reuse.
/// Compare against it when upgrading Capacitor.
enum CapacitorWebViewSetup {
    static func makeWebView(
        with configuration: InstanceConfiguration,
        assetHandler: WebViewAssetHandler,
        delegationHandler: WebViewDelegationHandler
    ) -> WKWebView {
        HTTPCookieStorage.shared.cookieAcceptPolicy = HTTPCookie.AcceptPolicy.always
        let webViewConfig = webViewConfiguration(for: configuration)
        webViewConfig.setURLSchemeHandler(assetHandler, forURLScheme: configuration.localURL.scheme ?? InstanceDescriptorDefaults.scheme)
        webViewConfig.userContentController = delegationHandler.contentController

        let webView = WKWebView(frame: .zero, configuration: webViewConfig)
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = configuration.contentInsetAdjustmentBehavior
        webView.allowsLinkPreview = configuration.allowLinkPreviews
        webView.scrollView.isScrollEnabled = configuration.scrollingEnabled

        if let overrideUserAgent = configuration.overridenUserAgentString {
            webView.customUserAgent = overrideUserAgent
        }

        let backgroundColor = configuration.backgroundColor ?? UIColor.systemBackground
        webView.backgroundColor = backgroundColor
        webView.scrollView.backgroundColor = backgroundColor
        webView.capacitor.setKeyboardShouldRequireUserInteraction(false)

        webView.uiDelegate = delegationHandler
        webView.navigationDelegate = delegationHandler
        if !configuration.zoomingEnabled {
            webView.scrollView.delegate = delegationHandler
        }
        return webView
    }

    private static func webViewConfiguration(for instanceConfiguration: InstanceConfiguration) -> WKWebViewConfiguration {
        let webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.websiteDataStore.httpCookieStore.add(CapacitorWKCookieObserver())
        webViewConfiguration.allowsInlineMediaPlayback = true
        webViewConfiguration.suppressesIncrementalRendering = false
        webViewConfiguration.allowsAirPlayForMediaPlayback = true
        webViewConfiguration.mediaTypesRequiringUserActionForPlayback = []
        webViewConfiguration.limitsNavigationsToAppBoundDomains = instanceConfiguration.limitsNavigationsToAppBoundDomains
        webViewConfiguration.preferences.isElementFullscreenEnabled = true

        if let appendUserAgent = instanceConfiguration.appendedUserAgentString {
            if let appName = webViewConfiguration.applicationNameForUserAgent {
                webViewConfiguration.applicationNameForUserAgent = "\(appName) \(appendUserAgent)"
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

    static func logWarnings(for descriptor: InstanceDescriptor) {
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
        }
    }

    static func printLoadError(startFile: URL) {
        CAPLog.print("⚡️  ERROR: Unable to load \(startFile.path)")
        CAPLog.print("⚡️  This file is the root of your web app and must exist before")
        CAPLog.print("⚡️  Capacitor can run. Ensure you've run capacitor copy at least")
        CAPLog.print("⚡️  or, if embedding, that this directory exists as a resource directory.")
    }
}
