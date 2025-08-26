import Flutter
import UIKit
import NXFitAuth
import NXFitConfig
import NXFitSync
import Combine
import Logging

public class NxfitSyncSdkPlugin: NSObject, FlutterPlugin {
    private let logger: Logger
    private let messageChannel: FlutterBasicMessageChannel
    private let authProvider: AuthProviding
    private var configProvider: ConfigurationProviding?
    private var syncSdk: NXFitSync?
    private var authStatusSubscription: AnyCancellable? = nil
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.neoex.sdk", binaryMessenger: registrar.messenger())
        let instance = NxfitSyncSdkPlugin(with: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public init(with registrar: FlutterPluginRegistrar) {
        self.logger = Logger(label: "com.neoex.nxfit.sync.bridge.NxfitSyncSdkPlugin")
        self.logger.debug("plugin init")
        
        self.messageChannel = FlutterBasicMessageChannel(name: "com.neoex.sdk/authProvider", binaryMessenger:  registrar.messenger(), codec: FlutterJSONMessageCodec())
        self.authProvider = AuthProviderImpl(self.messageChannel)
        
        super.init();
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.logger.debug("handling: \(call.method)")
        
        switch call.method {
            case "configure":
                guard let args = call.arguments as? [String: Any] else {
                    result(FlutterError(code: "InvalidArguments", message: "Invalid arguments.", details: nil))
                    return
                }

                self.handleConfigure(args, result)

            case "connect":
                self.handleConnect(result)

            case "disconnect":
                self.handleDisconnect(result)

            case "isConnected":
                self.handleIsConnected(result)

            case "purgeCache":
                self.handlePurgeCache(result)

            case "sync":
                self.handleSync(result)

            default:
                result(FlutterMethodNotImplemented)
        }
    }

    private func handleConfigure(_ args: [String: Any], _ result: @escaping FlutterResult) {
        guard let url = args["baseUrl"] as? String, let parsedUrl = URL(string: url) else {
            result(FlutterError(code: "InvalidArguments", message: "Invalid baseUrl argument.", details: nil))
            return
        }

        self.configProvider = ConfigProviderImpl(baseUrl: parsedUrl)

        self.authStatusSubscription = self.authProvider.authState
            .receive(on: RunLoop.main)
            .sink { [weak self] (state) in
                guard let self = self else {
                    return
                }
                
                if case let AuthState.authenticated(_) = state, let configProvider = self.configProvider {
                    self.syncSdk = NXFitSyncFactory.build(configProvider, self.authProvider)
                }
            }

        result(nil)
    }

    private func handleConnect(_ result: @escaping FlutterResult) {
        guard let syncSdk = self.syncSdk else {
            result(FlutterError(code: "InvalidState", message: "Invalid state, SDK not built.", details: nil))
            return
        }

        Task {
            await self.syncSdk?.connect()

            result(nil)
        }
    }

    private func handleDisconnect(_ result: @escaping FlutterResult) {
        guard let syncSdk = self.syncSdk else {
            result(FlutterError(code: "InvalidState", message: "Invalid state, SDK not built.", details: nil))
            return
        }

        Task {
            await self.syncSdk?.disconnect()

            result(nil)
        }
    }
    
    private func handleIsConnected(_ result: @escaping FlutterResult) {
        guard let syncSdk = self.syncSdk else {
            result(FlutterError(code: "InvalidState", message: "Invalid state, SDK not built.", details: nil))
            return
        }

        result(self.syncSdk?.isConnected() ?? false)
    }

    private func handlePurgeCache(_ result: @escaping FlutterResult) {
        guard let syncSdk = self.syncSdk else {
            result(FlutterError(code: "InvalidState", message: "Invalid state, SDK not built.", details: nil))
            return
        }

        Task {
            do {
                try await self.syncSdk?.purgeCache()

                result(nil)
            }
            catch {
                result(FlutterError(code: "InvalidOperation", message: "Failed to purge cache", details: nil))
            }
        }
    }

    private func handleSync(_ result: @escaping FlutterResult) {
       guard let syncSdk = self.syncSdk else {
            result(FlutterError(code: "InvalidState", message: "Invalid state, SDK not built.", details: nil))
            return
        }

        Task {
            await self.syncSdk?.sync()

            result(nil)
        }
    }
}
