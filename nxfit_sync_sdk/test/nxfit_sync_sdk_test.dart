import 'package:flutter_test/flutter_test.dart';
import 'package:nxfit_sync_sdk/nxfit_sync_sdk.dart';
import 'package:nxfit_sync_sdk/nxfit_sync_sdk_platform_interface.dart';
import 'package:nxfit_sync_sdk/nxfit_sync_sdk_impl.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:nxfit_sdk/core.dart';

// Mock platform implementation for testing
class MockNxfitSyncSdkPlatform
    with MockPlatformInterfaceMixin
    implements NxfitSyncSdkPlatform {
  
  bool _isConnected = false;
  bool _initCalled = false;
  bool _connectCalled = false;
  bool _disconnectCalled = false;
  bool _purgeCacheCalled = false;
  bool _syncCalled = false;

  // Getters to verify method calls in tests
  bool get initCalled => _initCalled;
  bool get connectCalled => _connectCalled;
  bool get disconnectCalled => _disconnectCalled;
  bool get purgeCacheCalled => _purgeCacheCalled;
  bool get syncCalled => _syncCalled;

  @override
  Future<void> init(AuthProvider authProvider, ConfigurationProvider configProvider) async {
    _initCalled = true;
  }

  @override
  Future<void> connect() async {
    _connectCalled = true;
    _isConnected = true;
  }

  @override
  Future<void> disconnect() async {
    _disconnectCalled = true;
    _isConnected = false;
  }

  @override
  Future<bool> isConnected() async {
    return _isConnected;
  }

  @override
  Future<void> purgeCache() async {
    _purgeCacheCalled = true;
  }

  @override
  Future<void> sync() async {
    _syncCalled = true;
  }

  // Helper methods for testing
  void reset() {
    _isConnected = false;
    _initCalled = false;
    _connectCalled = false;
    _disconnectCalled = false;
    _purgeCacheCalled = false;
    _syncCalled = false;
  }
}

// Mock implementations for dependencies
class MockAuthProvider implements AuthProvider {
  @override
  Stream<AuthState> get authState => Stream.value(
        Authenticated('test_token', 123),
      );

  @override
  AuthState get currentAuthState => Authenticated('test_token', 123);
}

class MockConfigProvider implements ConfigurationProvider {
  @override
  String get baseUrl => 'https://api.test.com';

  @override
  int get connectTimeoutSeconds => 30;

  @override
  HttpLoggerLevel get httpLoggerLevel => HttpLoggerLevel.none;
}

void main() {
  late MockNxfitSyncSdkPlatform mockPlatform;
  late MockAuthProvider mockAuthProvider;
  late MockConfigProvider mockConfigProvider;
  late NxfitSyncSdk nxfitSyncSdk;

  setUpAll(() {
    mockPlatform = MockNxfitSyncSdkPlatform();
    NxfitSyncSdkPlatform.instance = mockPlatform;
  });

  setUp(() {
    mockPlatform.reset();
    mockAuthProvider = MockAuthProvider();
    mockConfigProvider = MockConfigProvider();
  });

  group('Platform Interface Tests', () {
    test('default instance should be NxfitSyncSdkImpl', () {
      // Reset to default implementation
      NxfitSyncSdkPlatform.instance = NxfitSyncSdkImpl();
      final initialPlatform = NxfitSyncSdkPlatform.instance;
      expect(initialPlatform, isInstanceOf<NxfitSyncSdkImpl>());
      
      // Restore mock for other tests
      NxfitSyncSdkPlatform.instance = mockPlatform;
    });

    test('can set custom platform instance', () {
      final customPlatform = MockNxfitSyncSdkPlatform();
      NxfitSyncSdkPlatform.instance = customPlatform;
      expect(NxfitSyncSdkPlatform.instance, equals(customPlatform));
      
      // Restore original mock
      NxfitSyncSdkPlatform.instance = mockPlatform;
    });
  });

  group('NxfitSyncSdk Tests', () {
    setUp(() async {
      nxfitSyncSdk = await NxfitSyncSdk.build(mockConfigProvider, mockAuthProvider);
    });

    test('build method should initialize platform with providers', () {
      expect(mockPlatform.initCalled, isTrue);
    });

    test('build method should store providers as properties', () {
      expect(nxfitSyncSdk.configProvider, equals(mockConfigProvider));
      expect(nxfitSyncSdk.authProvider, equals(mockAuthProvider));
    });

    test('connect should call platform connect method', () async {
      await nxfitSyncSdk.connect();
      expect(mockPlatform.connectCalled, isTrue);
    });

    test('disconnect should call platform disconnect method', () async {
      await nxfitSyncSdk.disconnect();
      expect(mockPlatform.disconnectCalled, isTrue);
    });

    test('isConnected should return platform connection status', () async {
      // Initially not connected
      bool connected = await nxfitSyncSdk.isConnected();
      expect(connected, isFalse);

      // Connect and check again
      await nxfitSyncSdk.connect();
      connected = await nxfitSyncSdk.isConnected();
      expect(connected, isTrue);

      // Disconnect and check again
      await nxfitSyncSdk.disconnect();
      connected = await nxfitSyncSdk.isConnected();
      expect(connected, isFalse);
    });

    test('purgeCache should call platform purgeCache method', () async {
      await nxfitSyncSdk.purgeCache();
      expect(mockPlatform.purgeCacheCalled, isTrue);
    });

    test('sync should call platform sync method', () async {
      await nxfitSyncSdk.sync();
      expect(mockPlatform.syncCalled, isTrue);
    });

    test('multiple operations should work in sequence', () async {
      // Connect
      await nxfitSyncSdk.connect();
      expect(mockPlatform.connectCalled, isTrue);
      expect(await nxfitSyncSdk.isConnected(), isTrue);

      // Sync
      await nxfitSyncSdk.sync();
      expect(mockPlatform.syncCalled, isTrue);

      // Purge cache
      await nxfitSyncSdk.purgeCache();
      expect(mockPlatform.purgeCacheCalled, isTrue);

      // Disconnect
      await nxfitSyncSdk.disconnect();
      expect(mockPlatform.disconnectCalled, isTrue);
      expect(await nxfitSyncSdk.isConnected(), isFalse);
    });

    test('should handle multiple SDK instances', () async {
      final sdk1 = await NxfitSyncSdk.build(mockConfigProvider, mockAuthProvider);
      final sdk2 = await NxfitSyncSdk.build(mockConfigProvider, mockAuthProvider);

      expect(sdk1.configProvider, equals(mockConfigProvider));
      expect(sdk2.configProvider, equals(mockConfigProvider));
      expect(sdk1.authProvider, equals(mockAuthProvider));
      expect(sdk2.authProvider, equals(mockAuthProvider));
    });
  });

  group('Error Handling Tests', () {
    late MockNxfitSyncSdkPlatform errorPlatform;

    setUp(() async {
      errorPlatform = MockNxfitSyncSdkPlatform();
      NxfitSyncSdkPlatform.instance = errorPlatform;
      nxfitSyncSdk = await NxfitSyncSdk.build(mockConfigProvider, mockAuthProvider);
    });

    tearDown(() {
      // Restore original mock
      NxfitSyncSdkPlatform.instance = mockPlatform;
    });

    test('should handle connect errors gracefully', () async {
      // Use a platform that only throws on connect, not init
      final connectErrorPlatform = _ConnectErrorPlatform();
      NxfitSyncSdkPlatform.instance = connectErrorPlatform;
      nxfitSyncSdk = await NxfitSyncSdk.build(mockConfigProvider, mockAuthProvider);

      expect(
        () => nxfitSyncSdk.connect(),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle sync errors gracefully', () async {
      // Use a platform that only throws on sync, not init
      final syncErrorPlatform = _SyncErrorPlatform();
      NxfitSyncSdkPlatform.instance = syncErrorPlatform;
      nxfitSyncSdk = await NxfitSyncSdk.build(mockConfigProvider, mockAuthProvider);

      expect(
        () => nxfitSyncSdk.sync(),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle build errors gracefully', () async {
      // Override init to throw an error
      final initErrorPlatform = _InitErrorPlatform();
      NxfitSyncSdkPlatform.instance = initErrorPlatform;

      expect(
        () => NxfitSyncSdk.build(mockConfigProvider, mockAuthProvider),
        throwsA(isA<Exception>()),
      );
    });
  });
}

// Helper classes for error testing
class _ConnectErrorPlatform extends MockNxfitSyncSdkPlatform {
  @override
  Future<void> connect() async {
    throw Exception('Connection failed');
  }
}

class _SyncErrorPlatform extends MockNxfitSyncSdkPlatform {
  @override
  Future<void> sync() async {
    throw Exception('Sync failed');
  }
}

class _InitErrorPlatform extends MockNxfitSyncSdkPlatform {
  @override
  Future<void> init(AuthProvider authProvider, ConfigurationProvider configProvider) async {
    throw Exception('Init failed');
  }
}
