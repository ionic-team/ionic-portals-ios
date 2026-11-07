import Foundation
import Capacitor
import Combine

@objc(IONPortalsPlugin)
public final class PortalsPlugin: CAPInstancePlugin, CAPBridgedPlugin {
    public let identifier = "IONPortalsPlugin"
    public let jsName = "Portals"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "publishNative", returnType: CAPPluginReturnPromise)
    ]
    
    private let subscriptions = ConcurrentDictionary<AnyCancellable>()
    private let pubsub: PortalsPubSub
    
    public init(pubsub: PortalsPubSub = .shared) {
        self.pubsub = pubsub
        super.init()
    }
    
    @objc func publishNative(_ call: CAPPluginCall) {
        guard let topic = call.getString("topic") else {
            return call.reject("topic not provided")
        }
        
        let data = call.getValue("data")
        pubsub.publish(data, to: topic)
        call.resolve()
    }
    
    public override func addEventListener(_ eventName: String, listener: CAPPluginCall) {
        super.addEventListener(eventName, listener: listener)
        _ = subscriptions.value(forKey: eventName, default: pubsub.publisher(for: eventName)
            .sink { [weak self] result in
                self?.notifyListeners(
                    eventName,
                    data: result.dictionaryRepresentation as [String: Any]
                )
            }
        )
    }
}
