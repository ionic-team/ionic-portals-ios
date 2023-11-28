import Foundation

struct ServerUrl {
    var variableName: String
    var url: URL? {
        ProcessInfo.processInfo.environment[variableName].flatMap(URL.init)
    }
}

struct ConfigUrl {
    var variableName: String

    var url: URL? {
        guard let value = ProcessInfo.processInfo.environment[variableName],
              let decodedData = Data(base64Encoded: value, options: [.ignoreUnknownCharacters]),
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

struct DevConfiguration {
    var server: ServerUrl
    var capacitorConfig: ConfigUrl

    init(server: ServerUrl, capacitorConfig: ConfigUrl) {
        self.server = server
        self.capacitorConfig = capacitorConfig
    }
}

extension DevConfiguration {
    init(baseName: String) {
        server = .init(variableName: "\(baseName.uppercased())_SERVER") 
        capacitorConfig = .init(variableName: "\(baseName.uppercased())_CONFIG")
    }
}

extension DevConfiguration {
    static let `default` = DevConfiguration(baseName: "PORTAL")
}
