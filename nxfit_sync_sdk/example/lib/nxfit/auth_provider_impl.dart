import 'package:nxfit_sdk/core.dart';
import 'package:rxdart/rxdart.dart';

class AuthProviderImpl implements AuthProvider {
  final BehaviorSubject<AuthState> _authState = BehaviorSubject<AuthState>.seeded(Unauthenticated());
  final int _userId = 1;
  final String _authToken = "";

  @override
  Stream<AuthState> get authState => _authState.asBroadcastStream();

  @override
  AuthState get currentAuthState => _authState.value;

  void login() {
    print("setting authenticated");

    _authState.sink.add(Authenticated(_authToken, _userId));
  }

  void logout() {
    print("setting unauthenticated");

    _authState.sink.add(Unauthenticated());
  }
}