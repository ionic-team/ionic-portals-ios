# Live Updates

Configure a portal with Ionic Live Updates or an external live update provider.

## Ionic Live Updates

Use ``Portal/LiveUpdateProvider/ionic(liveUpdateManager:liveUpdateConfig:)`` with a `LiveUpdate` configuration:

```swift
import IonicLiveUpdates
import IonicPortals

let portal = Portal(
    name: "checkout",
    liveUpdateProvider: .ionic(
        liveUpdateConfig: LiveUpdate(
            appId: "checkout-app",
            channel: "production"
        )
    )
)
```

Call ``Portal/sync()`` to synchronize a portal configured with Ionic Live Updates:

```swift
let result = try await portal.sync()
print(result.source)
```

## External Providers

Use ``Portal/LiveUpdateProvider/provider(liveUpdateManager:)`` with a manager that conforms to `LiveUpdateManaging` from the Live Update Provider SDK:

```swift
import IonicPortals
import LiveUpdateProvider

let portal = Portal(
    name: "checkout",
    liveUpdateProvider: .provider(liveUpdateManager: manager)
)
```

Call ``Portal/syncProvider()`` to synchronize a portal configured with an external live update provider:

```swift
let result = try await portal.syncProvider()
print(result)
```

When a `PortalUIView` reloads, Portals uses ``Portal/latestAppDirectory`` to switch the web view to newly activated assets.

Objective-C apps can continue to configure Ionic Live Updates with `setLiveUpdateConfiguration(appId:channel:syncImmediately:)`. That method does not replace an existing external provider.
