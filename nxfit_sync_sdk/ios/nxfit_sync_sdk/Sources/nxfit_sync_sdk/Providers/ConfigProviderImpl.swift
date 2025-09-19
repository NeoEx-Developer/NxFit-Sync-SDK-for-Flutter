import Flutter
import NXFitConfig

internal class ConfigProviderImpl : ConfigurationProviding {
    private let config: Configuration

    init(baseUrl: URL) {
        self.config = Configuration(baseUrl: baseUrl)
    }

    var configuration: Configuration {
        config
    }
}
