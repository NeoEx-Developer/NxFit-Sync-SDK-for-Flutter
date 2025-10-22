import Flutter
import NXFitConfig

internal class ConfigProviderImpl : ConfigurationProviding {
    private let config: Configuration
    
    init(baseUrl: URL, httpLogLevel: HttpLogLevel = .none) {
        self.config = Configuration(baseUrl: baseUrl, httpLogLevel: httpLogLevel)
    }

    var configuration: Configuration {
        config
    }
}
