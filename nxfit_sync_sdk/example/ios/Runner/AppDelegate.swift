import Flutter
import UIKit
import NXFitSync
import NXFitConfig
import Logging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {      
      LoggingSystem.bootstrap { label in
          var handler = StreamLogHandler.standardOutput(label: label)
          handler.logLevel = Logger.Level.trace
          return handler
      }

      GeneratedPluginRegistrant.register(with: self)

      Task {
          if let (userId, accessToken) = auth() {
              NXFitSyncBackground.enableHealthKitBackgroundDelivery(ConfigProviderImpl(baseUrl: URL(string: "https://api.dev.nxfit.io")!), userId: userId, accessToken: accessToken)
          }
      }
      
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    private func auth() -> (Int, String)? {
        let userId = 1
        let authToken = ""
        
        return (userId, authToken)
    }
}

class ConfigProviderImpl : ConfigurationProviding {
    private let config: Configuration

    init(baseUrl: URL) {
        self.config = Configuration(baseUrl: baseUrl)
    }

    var configuration: Configuration {
        config
    }
}
