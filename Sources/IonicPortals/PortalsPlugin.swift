import Foundation
import Capacitor

@objc(IONPortalsPlugin)
internal final class Plugin: CAPPlugin, CAPBridgedPlugin {
    static func pluginId() -> String {
        "IONPortalsPlugin"
    }
    
    static func jsName() -> String {
        "Portals"
    }
    
    static let methods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "publishNative", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "subscribeNative", returnType: CAPPluginReturnCallback),
        CAPPluginMethod(name: "unsubscribeNative", returnType: CAPPluginReturnPromise)
    ]
    
    static func pluginMethods() -> [Any] { methods }
    
    static func getMethod(_ methodName: String) -> CAPPluginMethod? {
        methods.first { $0.name == methodName }
    }
    
    @objc func publishNative(_ call: CAPPluginCall) {
        guard let topic = call.getString("topic") else {
            return call.reject("topic not provided")
        }
        
        let data = call.getValue("data")
        PortalsPubSub.publish(data, to: topic)
        call.resolve()
    }
    
    @objc func subscribeNative(_ call: CAPPluginCall) {
        guard let topic = call.getString("topic") else {
            call.reject("topic not provided")
            return
        }
        call.keepAlive = true
        
        let ref = IONPortalsPubSub.subscribe(topic: topic, callback: call.resolve)
        call.resolve([
            "topic": topic,
            "subscriptionRef": ref
        ])
    }
    
    @objc func unsubscribeNative(_ call: CAPPluginCall) {
        guard let topic = call.getString("topic") else {
            call.reject("topic not provided")
            return
        }
        guard let subscriptionRef = call.getInt("subscriptionRef") else {
            call.reject("subscriptionRef not provided")
            return
        }
        PortalsPubSub.unsubscribe(from: topic, subscriptionRef: subscriptionRef)
        call.resolve()
    }
}

