import Flutter
import AsyncExtensions
import NXFitAuth
import Logging

internal class AuthProviderImpl : AuthProviding {
    private let logger: Logger
    private let messageChannel: FlutterBasicMessageChannel
    private var _userId: Int = 0
    private let _authState = AsyncCurrentValueSubject<AuthState>(.unauthenticated)

    init(_ messageChannel: FlutterBasicMessageChannel) {
        self.logger = Logger(label: "com.neoex.nxfit.sync.bridge.AuthProviderImpl")
        self.messageChannel = messageChannel
        self.messageChannel.setMessageHandler { [weak self] (arguments, reply) in
            self?.logger.debug("received auth state: \(String(describing: arguments))")

            guard let self = self, let args = arguments as? [String: Any] else { return }

            if let userId = args["userId"] as? Int, let accessToken = args["accessToken"] as? String {
                self.logger.debug("sending authenticated state")
                self._userId = userId
                self._authState.send(.authenticated(accessToken))
            }
            else {
                self.logger.debug("sending unauthenticated state")
                self._userId = 0
                self._authState.send(.unauthenticated)
            }
        }
    }

    public var userId: Int {
        return _userId
    }

    public var authState: AnyAsyncSequence<AuthState> {
        return _authState.removeDuplicates().eraseToAnyAsyncSequence()
    }
}

extension AuthState : Equatable {
    public static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        return lhs.value == rhs.value
    }
    
    internal var value: String {
        return String(describing: self)
    }
}
