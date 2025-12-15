import 'package:flutter_test/flutter_test.dart';
import 'package:nxfit_sdk/models.dart';
import 'package:nxfit_sync_sdk/nxfit_sync_sdk.dart';
import 'package:nxfit_sync_sdk/nxfit_sync_sdk_platform.dart';
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
  bool _syncExerciseSessionsCalled = false;
  bool _syncDailyMetricsCalled = false;
  bool _getIntegrationsCalled = false;

  // Getters to verify method calls in tests
  bool get initCalled => _initCalled;
  bool get connectCalled => _connectCalled;
  bool get disconnectCalled => _disconnectCalled;
  bool get purgeCacheCalled => _purgeCacheCalled;
  bool get syncExerciseSessionsCalled => _syncExerciseSessionsCalled;
  bool get syncDailyMetricsCalled => _syncDailyMetricsCalled;
  bool get getIntegrationsCalled => _getIntegrationsCalled;


  @override
  Future<void> init(AuthProvider authProvider, ConfigurationProvider configProvider) async {
    _initCalled = true;
  }

  @override
  Future<void> connect(String integrationIdentifier) async {
    _connectCalled = true;
    _isConnected = true;
  }

  @override
  Future<void> disconnect(String integrationIdentifier) async {
    _disconnectCalled = true;
    _isConnected = false;
  }

  @override
  Future<void> purgeCache() async {
    _purgeCacheCalled = true;
  }

  @override
  Future<void> syncExerciseSessions() async {
    _syncExerciseSessionsCalled = true;
  }

  @override
  Future<void> syncDailyMetrics() async {
    _syncDailyMetricsCalled = true;
  }

  @override
  Future<List<LocalIntegration>> getIntegrations() async {
    _getIntegrationsCalled = true;

    return [LocalIntegration('health_connect', _isConnected, IntegrationAvailability.available)];
  }

  @override
  Stream<bool> get isReady => Stream.value(true);

  // Helper methods for testing
  void reset() {
    _isConnected = false;
    _initCalled = false;
    _connectCalled = false;
    _disconnectCalled = false;
    _purgeCacheCalled = false;
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
  LogLevel get minLogLevel => LogLevel.info;

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
      final integrationId = "health_connect";

      await nxfitSyncSdk.connect(integrationId);
      expect(mockPlatform.connectCalled, isTrue);
    });

    test('disconnect should call platform disconnect method', () async {
      final integrationId = "health_connect";

      await nxfitSyncSdk.disconnect(integrationId);
      expect(mockPlatform.disconnectCalled, isTrue);
    });

    test('getIntegrations should call platform getIntegrations method', () async {
      await nxfitSyncSdk.getIntegrations();
      expect(mockPlatform.getIntegrationsCalled, isTrue);
    });

    test('purgeCache should call platform purgeCache method', () async {
      await nxfitSyncSdk.purgeCache();
      expect(mockPlatform.purgeCacheCalled, isTrue);
    });

    test('syncExerciseSessions should call platform sync method', () async {
      await nxfitSyncSdk.syncExerciseSessions();
      expect(mockPlatform.syncExerciseSessionsCalled, isTrue);
    });

    test('syncDailyMetrics should call platform sync method', () async {
      await nxfitSyncSdk.syncDailyMetrics();
      expect(mockPlatform.syncDailyMetricsCalled, isTrue);
    });


    test('multiple operations should work in sequence', () async {
      final integrationId = "health_connect";

      // Connect
      await nxfitSyncSdk.connect(integrationId);
      expect(mockPlatform.connectCalled, isTrue);
      var integrations = await nxfitSyncSdk.getIntegrations();
      expect(integrations.singleWhere((i) => i.identifier == integrationId).isConnected, isTrue);

      // Sync
      await nxfitSyncSdk.syncExerciseSessions();
      await nxfitSyncSdk.syncDailyMetrics();

      expect(mockPlatform.syncExerciseSessionsCalled, isTrue);
      expect(mockPlatform.syncDailyMetricsCalled, isTrue);

      // Purge cache
      await nxfitSyncSdk.purgeCache();
      expect(mockPlatform.purgeCacheCalled, isTrue);

      // Disconnect
      await nxfitSyncSdk.disconnect(integrationId);
      expect(mockPlatform.disconnectCalled, isTrue);
      integrations = await nxfitSyncSdk.getIntegrations();
      expect(integrations.singleWhere((i) => i.identifier == integrationId).isConnected, isFalse);
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
      final integrationId = "health_connect";

      // Use a platform that only throws on connect, not init
      final connectErrorPlatform = _ConnectErrorPlatform();
      NxfitSyncSdkPlatform.instance = connectErrorPlatform;
      nxfitSyncSdk = await NxfitSyncSdk.build(mockConfigProvider, mockAuthProvider);

      expect(
        () => nxfitSyncSdk.connect(integrationId),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle sync errors gracefully', () async {
      // Use a platform that only throws on sync, not init
      final syncErrorPlatform = _SyncErrorPlatform();
      NxfitSyncSdkPlatform.instance = syncErrorPlatform;
      nxfitSyncSdk = await NxfitSyncSdk.build(mockConfigProvider, mockAuthProvider);

      expect(
        () => nxfitSyncSdk.syncDailyMetrics(),
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
  Future<void> connect(String integrationIdentifier) async {
    throw Exception('Connection failed');
  }
}

class _SyncErrorPlatform extends MockNxfitSyncSdkPlatform {
  @override
  Future<void> syncDailyMetrics() async {
    throw Exception('Sync failed');
  }
}

class _InitErrorPlatform extends MockNxfitSyncSdkPlatform {
  @override
  Future<void> init(AuthProvider authProvider, ConfigurationProvider configProvider) async {
    throw Exception('Init failed');
  }
}
