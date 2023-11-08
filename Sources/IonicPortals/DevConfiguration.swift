import Foundation

struct EnvironmentValue {
    var variableName: String
    var url: URL? {
        ProcessInfo.processInfo.environment[variableName].flatMap(URL.init)
    }
}

struct DevelopmentConfiguration {
    var server: EnvironmentValue
    var capacitorConfig: EnvironmentValue

    init(server: EnvironmentValue, capacitorConfig: EnvironmentValue) {
        self.server = server
        self.capacitorConfig = capacitorConfig
    }
}

extension DevelopmentConfiguration {
    init(baseEnvironmentVariable: String) {
        server = .init(variableName: "\(baseEnvironmentVariable.uppercased())_SERVER") 
        capacitorConfig = .init(variableName: "\(baseEnvironmentVariable.uppercased())_CONFIG")
    }
}

extension DevelopmentConfiguration {
    static var `default` = DevelopmentConfiguration(baseEnvironmentVariable: "PORTAL")
}
