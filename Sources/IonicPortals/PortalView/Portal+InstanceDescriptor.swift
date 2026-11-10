import Foundation
import Capacitor

extension Portal {
    /// The Capacitor instance that runs this portal, loading it from `liveUpdateDirectory` if given
    func instanceDescriptor(liveUpdateDirectory: URL?) -> InstanceDescriptor {
        #if DEBUG
        let devConfiguration = devModeEnabled ? DevConfiguration(portalName: name) : nil
        let descriptor = devConfiguration?.capacitorConfigUrl.map {
            InstanceDescriptor(at: Bundle.main.bundleURL, configuration: $0, cordovaConfiguration: nil)
        } ?? appInstanceDescriptor(liveUpdateDirectory: liveUpdateDirectory)
        #else
        let descriptor = appInstanceDescriptor(liveUpdateDirectory: liveUpdateDirectory)
        #endif

        descriptor.handleApplicationNotifications = false
        descriptorConfiguration.forEach { $0(descriptor) }

        #if DEBUG
        if let serverUrl = devConfiguration?.serverUrl {
            descriptor.serverURL = serverUrl.absoluteString
            // This allows for not having any files on disk during dev
            if !FileManager.default.fileExists(atPath: descriptor.appLocation.path) {
                descriptor.appLocation = Bundle.main.bundleURL
            }
        }
        #endif

        return descriptor
    }

    private func appInstanceDescriptor(liveUpdateDirectory: URL?) -> InstanceDescriptor {
        let descriptor: InstanceDescriptor
        if let appDirectory = liveUpdateDirectory ?? bundledAppDirectory {
            let capConfigUrl = [appDirectory, bundledAppDirectory].lazy
                .compactMap { $0?.appendingPathComponent("capacitor.config.json") }
                .first { FileManager.default.fileExists(atPath: $0.path) }

            descriptor = InstanceDescriptor(at: appDirectory, configuration: capConfigUrl, cordovaConfiguration: nil)
        } else {
            // Without a location Capacitor would load the host app's own web app
            let expectedPath = (bundle.resourceURL ?? bundle.bundleURL).appendingPathComponent(startDir, isDirectory: true)
            descriptor = InstanceDescriptor(at: expectedPath, configuration: nil, cordovaConfiguration: nil)
        }

        #if DEBUG
        // Capacitor only enables web debugging in debug builds while reading a config file, which a Capacitor app always has
        if descriptor.warnings.contains(.missingFile) {
            descriptor.isWebDebuggable = true
        }
        #endif
        return descriptor
    }
}
