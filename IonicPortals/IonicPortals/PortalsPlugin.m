#import <Capacitor/Capacitor.h>

CAP_PLUGIN(IONPortalsPlugin, "Portals",
  CAP_PLUGIN_METHOD(publishNative, CAPPluginReturnPromise);
  CAP_PLUGIN_METHOD(subscribeNative, CAPPluginReturnCallback);
  CAP_PLUGIN_METHOD(unsubscribeNative, CAPPluginReturnPromise);
)
