import Foundation
import Capacitor
import Combine

@objc(IONPortalsPlugin)
internal class Plugin: CAPPlugin {
    @objc func publishNative(_ call: CAPPluginCall) {
        guard let topic = call.getString("topic") else {
            return call.reject("topic not provided")
        }
        
        let data = call.getValue("data")
        PortalsPubSub.publish(topic, message: data)
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

