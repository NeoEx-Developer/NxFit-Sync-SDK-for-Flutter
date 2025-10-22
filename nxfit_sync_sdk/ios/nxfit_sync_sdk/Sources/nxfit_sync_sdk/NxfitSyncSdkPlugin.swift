import Flutter
import UIKit
import NXFitAuth
import NXFitConfig
import NXFitSync
import Combine
import Logging

public class NxfitSyncSdkPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private let logger: Logger
    private let messageChannel: FlutterBasicMessageChannel
    private var readyEventSink: FlutterEventSink?
    private let authProvider: AuthProviding
    private var configProvider: ConfigurationProviding?
    private var syncSdk: NXFitSync?
    private var authStatusSubscription: AnyCancellable? = nil
    private let appleIntegrationIdentifier = "apple"
    private let flutterResultCodeError = "ERROR"
    private let flutterResultCodeInvalidArgument = "INVALID_ARGUMENT"
    private let flutterResultCodeUnsupportedIntegration = "UNSUPPORTED_INTEGRATION"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.neoex.sdk", binaryMessenger: registrar.messenger())
        let instance = NxfitSyncSdkPlugin(with: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        let eventChannel = FlutterEventChannel(name: "com.neoex.sdk/readyState", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)
    }

    public init(with registrar: FlutterPluginRegistrar) {
        self.logger = Logger(label: "com.neoex.nxfit.sync.bridge.NxfitSyncSdkPlugin")
        self.logger.debug("plugin init")
        
        self.messageChannel = FlutterBasicMessageChannel(name: "com.neoex.sdk/authProvider", binaryMessenger:  registrar.messenger(), codec: FlutterJSONMessageCodec())
        self.authProvider = AuthProviderImpl(self.messageChannel)
        
        super.init();
        
        self.authStatusSubscription = self.authProvider.authState
            .receive(on: RunLoop.main)
            .sink { [weak self] (state) in
                guard let self = self else {
                    return
                }
                
                self.logger.debug("auth state \(state.value)")
                
                if case let AuthState.authenticated(_) = state, let configProvider = self.configProvider {
                    if self.syncSdk == nil {
                        self.syncSdk = NXFitSyncFactory.build(configProvider, self.authProvider)
                        self.readyEventSink?(true)
                    }
                }
                else {
                    self.syncSdk = nil
                    self.readyEventSink?(false)
                }
            }
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.logger.debug("plugin onListen fired")
        self.readyEventSink = events
        
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.logger.debug("plugin onCancel fired")
        
        self.readyEventSink = nil
        return nil
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.logger.debug("handling: \(call.method)")
        
        do {
            switch call.method {
            case "configure":
                try self.handleConfigure(call.arguments, result)
                
            case "connect":
                try self.handleConnect(call.arguments, result)
                
            case "disconnect":
                try self.handleDisconnect(call.arguments, result)
                
            case "getIntegrations":
                try self.handleGetIntegrations(result)
                
            case "purgeCache":
                try self.handlePurgeCache(result)
                
            case "syncExerciseSessions":
                try self.handleSyncExerciseSessions(result)
                
            case "syncDailyMetrics":
                try self.handleSyncHealth(result)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        catch PluginError.invalidArgument(let expectedArgument) {
            result(FlutterError(code: flutterResultCodeInvalidArgument, message: "Invalid argument provided for '\(expectedArgument)'.", details: nil))
        }
        catch PluginError.sdkNotBuilt {
            result(FlutterError(code: flutterResultCodeError, message: "Invalid state, SDK not built.", details: nil))
        }
        catch PluginError.unsupportedIntegration(let identifier) {
            result(FlutterError(code: flutterResultCodeUnsupportedIntegration, message: "'\(identifier)' is not supported. Only '\(appleIntegrationIdentifier)' integration is supported.", details: nil))
        }
        catch {
            result(FlutterError(code: flutterResultCodeError, message: error.localizedDescription, details: nil))
        }
    }

    private func handleConfigure(_ args: Any?, _ result: @escaping FlutterResult) throws {
        let parsedUrl = try assertArgumentValid(args, expectedArgument: "baseUrl", get: { (s) in URL(string: s)! })
        let httpLogLevel = try assertArgumentValid(args, expectedArgument: "httpLoggerLevel", get: { (s) in try Self.httpLogLevel(from: s) })

        self.configProvider = ConfigProviderImpl(baseUrl: parsedUrl, httpLogLevel: httpLogLevel)

        result(nil)
    }

    private func handleConnect(_ args: Any?, _ result: @escaping FlutterResult) throws {
        let identifier = try assertArgumentValid(args, expectedArgument: "integrationIdentifier", get: { (s) in s as! String })
        try assertIdentifierSupported(identifier)
        try assertSdkBuilt()

        Task {
            await self.syncSdk?.connect()

            result(nil)
        }
    }

    private func handleDisconnect(_ args: Any?, _ result: @escaping FlutterResult) throws {
        let identifier = try assertArgumentValid(args, expectedArgument: "integrationIdentifier", get: { (s) in s as! String })
        try assertIdentifierSupported(identifier)
        try assertSdkBuilt()

        Task {
            await self.syncSdk?.disconnect()

            result(nil)
        }
    }
    
    private func handleGetIntegrations(_ result: @escaping FlutterResult) throws {
        try assertSdkBuilt()

        let connected = self.syncSdk?.isConnected() ?? false
        
        do {
            let jsonData = try JSONEncoder().encode(
                LocalIntegrationList(integrations: [
                    LocalIntegration(identifier: appleIntegrationIdentifier, isConnected: connected, availability: .available)
                ])
            )

            result(String(data: jsonData, encoding: .utf8)!)
        }
        catch {
            result(FlutterError(code: flutterResultCodeError, message: "Unable to encode JSON.", details: nil))
        }
    }

    private func handlePurgeCache(_ result: @escaping FlutterResult) throws {
        try assertSdkBuilt()

        Task {
            do {
                try await self.syncSdk?.purgeCache()

                result(nil)
            }
            catch {
                result(FlutterError(code: flutterResultCodeError, message: "Failed to purge cache", details: nil))
            }
        }
    }

    private func handleSyncExerciseSessions(_ result: @escaping FlutterResult) throws {
        try assertSdkBuilt()

        Task {
            await self.syncSdk?.syncWorkouts()

            result(nil)
        }
    }
    
    private func handleSyncHealth(_ result: @escaping FlutterResult) throws {
        try assertSdkBuilt()

        Task {
            await self.syncSdk?.syncHealth()

            result(nil)
        }
    }
    
    private func assertArgumentValid<T>(_ arguments: Any?, expectedArgument: String, get: (String) throws -> T) throws -> T  {
        guard let args = arguments as? [String: Any], let arg = args[expectedArgument] as? String, let parsedArg = try? get(arg) else {
            throw PluginError.invalidArgument(expectedArgument)
        }
        
        return parsedArg
    }
    
    private func assertIdentifierSupported(_ identifier: String) throws {
        guard identifier == appleIntegrationIdentifier else {
            throw PluginError.unsupportedIntegration(identifier)
        }
    }
    
    private func assertSdkBuilt() throws {
        if self.syncSdk == nil {
            throw PluginError.sdkNotBuilt
        }
    }
    
    // Converts a string to HttpLogLevel in a case-insensitive manner.
    private static func httpLogLevel(from string: String) throws -> HttpLogLevel {
        let normalized = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        switch normalized {
            case "none":
                return .none
            case "errorsOnly":
                return .errorsOnly
            case "headers":
                return .headers
            case "body":
                return .body
            default:
                return .none
        }
    }
}

fileprivate enum PluginError : Error {
    case sdkNotBuilt, invalidArgument(_ argument: String), unsupportedIntegration(_ identifier: String)
}
