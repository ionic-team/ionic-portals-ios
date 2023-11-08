import Foundation

struct EnvironmentValue {
    var variableName: String
    var url: URL? {
        ProcessInfo.processInfo.environment[variableName].flatMap(URL.init)
    }
}

struct DevConfiguration {
    var server: EnvironmentValue
    var capacitorConfig: EnvironmentValue

    init(server: EnvironmentValue, capacitorConfig: EnvironmentValue) {
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
    static var `default` = DevConfiguration(baseName: "PORTAL")
}
