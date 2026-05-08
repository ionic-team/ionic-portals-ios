# ``IonicPortals/Portal``

Use a `Portal` to configure the web application, plugins, initial context, assets, and optional live update behavior that Portals should load.

## Live Updates

Portals supports Ionic Live Updates and external live update providers.

Use Ionic Live Updates by passing an Ionic-backed live update provider:

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

Use an external live update provider by passing a manager that conforms to `LiveUpdateManaging` from the Live Update Provider SDK. A provider manager should keep `latestAppDirectory` accurate when it is created and update it before `sync()` returns when new assets are active.

```swift
import Foundation
import IonicPortals
import LiveUpdateProvider

struct ProviderSyncResult: SyncResult {}

final class ProviderLiveUpdateManager: LiveUpdateManaging {
    private(set) var latestAppDirectory: URL?

    func sync() async throws -> any SyncResult {
        // Fetch, store, and activate the latest web assets.
        // Update latestAppDirectory before returning when new assets are active.
        ProviderSyncResult()
    }
}

let manager = ProviderLiveUpdateManager()

let portal = Portal(
    name: "checkout",
    liveUpdateProvider: .provider(liveUpdateManager: manager)
)
```

Call ``sync()`` to synchronize an Ionic-backed portal.

```swift
let ionicResult = try await portal.sync()
print(ionicResult.source)
```

Call ``syncProvider()`` to synchronize an external live update provider.

```swift
let providerResult = try await portal.syncProvider()
print(providerResult)
```

When a `PortalUIView` reloads, Portals uses ``latestAppDirectory`` to switch the web view to newly activated assets.

Objective-C apps can continue to configure Ionic Live Updates with `setLiveUpdateConfiguration(appId:channel:syncImmediately:)`. That method does not replace an existing external provider.

## Topics

### Create a Portal

- ``init(name:startDir:index:devModeEnabled:bundle:initialContext:assetMaps:plugins:liveUpdateProvider:)``
- ``init(stringLiteral:)``

### Web App Location 

- ``startDir``
- ``index``
- ``bundle``

### Plugin Management

- ``plugins``
- ``adding(_:)-72o29``
- ``adding(_:)-9sqqz``
- ``adding(_:)-868wl``
- ``adding(_:)-9lavd``
- ``adding(_:)-3kt0j``
- ``adding(_:)-9utyy``
- ``Plugin``

### Live Updates

- ``liveUpdateProvider``
- ``LiveUpdateProvider``
- ``sync()``
- ``syncProvider()``
- ``sync(_:)``
- ``syncProvider(_:)``
- ``latestAppDirectory``
- ``LiveUpdateNotConfigured``
- ``ParallelLiveUpdateSyncGroup``
- ``ParallelLiveUpdateProviderSyncGroup``

### Initial Application State

- ``initialContext``

### Configuring Capacitor

- ``configuring(_:_:)``

### Name

- ``name``

### DevMode

- ``devModeEnabled``

### Assets

- ``assetMaps``
