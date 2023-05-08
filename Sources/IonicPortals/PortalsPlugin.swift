import Foundation
import Capacitor
import Combine

@objc(IONPortalsPlugin)
public final class PortalsPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "IONPortalsPlugin"
    public let jsName = "Portals"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "publishNative", returnType: CAPPluginReturnPromise)
    ]
    
    private var publishers = ConcurrentDictionary(label: "io.ionic.portalsplugin", dict: [String: AnyCancellable]())
    private var pubsub: PortalsPubSub = .shared
    
    public convenience init(pubsub: PortalsPubSub) {
        self.init()
        self.pubsub = pubsub
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
        guard publishers[eventName] == nil else { return }
        publishers[eventName] = pubsub.publisher(for: eventName)
            .sink { [weak self] result in
                self?.notifyListeners(
                    eventName,
                    data: result.dictionaryRepresentation as [String: Any]
                )
            }
    }
}
