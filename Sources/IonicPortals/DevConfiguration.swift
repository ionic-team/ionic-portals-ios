import Foundation

#if DEBUG
/// Overrides set through environment variables named after the portal (e.g. `CHECKOUT_SERVER`),
/// falling back to ones shared by every portal (e.g. `PORTAL_SERVER`)
struct DevConfiguration {
    var serverUrl: URL?
    var capacitorConfigUrl: URL?

    init(portalName: String) {
        let environment = ProcessInfo.processInfo.environment
        let prefixes = [portalName.uppercased(), "PORTAL"]
        serverUrl = prefixes.lazy
            .compactMap { environment["\($0)_SERVER"].flatMap(URL.init(string:)) }
            .first
        capacitorConfigUrl = prefixes.lazy
            .compactMap { environment["\($0)_CONFIG"].flatMap(Self.writeConfig) }
            .first
    }

    /// Capacitor only reads its config from a file, so the base64 value is written to one
    private static func writeConfig(base64: String) -> URL? {
        guard let decodedData = Data(base64Encoded: base64, options: [.ignoreUnknownCharacters]),
              let decodedString = String(data: decodedData, encoding: .utf8)
        else { return nil }

        let targetTempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")

        do {
            try decodedString.write(to: targetTempFile, atomically: true, encoding: .utf8)
        } catch {
            return nil
        }

        return targetTempFile
    }
}
#endif
