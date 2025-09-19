import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nxfit_sdk/models.dart';
import 'package:nxfit_sync_sdk/nxfit/models/local_integration_list.dart';
import 'package:nxfit_sync_sdk/nxfit_sync_sdk_impl.dart';
import 'package:nxfit_sdk/core.dart';

// Mock implementations for testing
class MockAuthProvider implements AuthProvider {
  @override
  Stream<AuthState> get authState =>
      Stream.value(Authenticated('test_token', 123));

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
  TestWidgetsFlutterBinding.ensureInitialized();

  late NxfitSyncSdkImpl platform;
  late MockAuthProvider mockAuthProvider;
  late MockConfigProvider mockConfigProvider;
  const MethodChannel channel = MethodChannel('com.neoex.sdk');
  const BasicMessageChannel<Object?> authChannel = BasicMessageChannel<Object?>(
    'com.neoex.sdk/authProvider',
    JSONMessageCodec(),
  );

  setUp(() {
    platform = NxfitSyncSdkImpl();
    mockAuthProvider = MockAuthProvider();
    mockConfigProvider = MockConfigProvider();

    // Mock method channel responses
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'configure':
              return null;
            case 'connect':
              return null;
            case 'disconnect':
              return null;
            case 'isConnected':
              return true;
            case 'purgeCache':
              return null;
            case 'sync':
              return null;
            default:
              throw PlatformException(
                code: 'UNIMPLEMENTED',
                message: 'Method ${methodCall.method} not implemented',
              );
          }
        });

    // Mock auth message channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(authChannel.name, (dynamic message) async {
          return authChannel.codec.encodeMessage(null);
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(authChannel.name, null);
  });

  group('NxfitSyncSdkImpl Tests', () {
    test('init should configure the platform with providers', () async {
      // Verify init doesn't throw and completes successfully
      await expectLater(
        platform.init(mockAuthProvider, mockConfigProvider),
        completes,
      );
    });

    test('connect should invoke platform method', () async {
      final integrationId = "health_connect";

      // Setup
      bool connectCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == 'connect') {
              connectCalled = true;
            }
            return null;
          });

      // Execute
      await platform.connect(integrationId);

      // Verify
      expect(connectCalled, isTrue);
    });

    test('disconnect should invoke platform method', () async {
      final integrationId = "health_connect";

      // Setup
      bool disconnectCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == 'disconnect') {
              disconnectCalled = true;
            }
            return null;
          });

      // Execute
      await platform.disconnect(integrationId);

      // Verify
      expect(disconnectCalled, isTrue);
    });

    test('getIntegrations should invoke platform method', () async {
      // Setup
      bool getIntegrationsCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == 'getIntegrations') {
              getIntegrationsCalled = true;
              return jsonEncode(LocalIntegrationList(integrations: []));
            }
            return null;
          });

      // Execute
      final integrations = await platform.getIntegrations();

      // Verify
      expect(getIntegrationsCalled, isTrue);
      expect(integrations, isA<List<LocalIntegration>>());
    });

    test('purgeCache should invoke platform method', () async {
      // Setup
      bool purgeCacheCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == 'purgeCache') {
              purgeCacheCalled = true;
            }
            return null;
          });

      // Execute
      await platform.purgeCache();

      // Verify
      expect(purgeCacheCalled, isTrue);
    });

    test('syncExerciseSessions should invoke platform method', () async {
      // Setup
      bool syncCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == 'syncExerciseSessions') {
              syncCalled = true;
            }
            return null;
          });

      // Execute
      await platform.syncExerciseSessions();

      // Verify
      expect(syncCalled, isTrue);
    });

    test('syncDailyMetrics should invoke platform method', () async {
      // Setup
      bool syncCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == 'syncDailyMetrics') {
              syncCalled = true;
            }
            return null;
          });

      // Execute
      await platform.syncDailyMetrics();

      // Verify
      expect(syncCalled, isTrue);
    });

    test(
      'configure should be called with correct parameters during init',
      () async {
        // Setup
        Map<String, dynamic>? configureArgs;
        bool configureCalled = false;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
              if (methodCall.method == 'configure') {
                configureCalled = true;
                configureArgs = Map<String, dynamic>.from(
                  methodCall.arguments as Map,
                );
              }
              return null;
            });

        // Execute
        await platform.init(mockAuthProvider, mockConfigProvider);

        // Verify
        expect(configureCalled, isTrue);
        expect(configureArgs, isNotNull);
        expect(configureArgs!['baseUrl'], equals('https://api.test.com'));
      },
    );

    test('should handle platform exceptions gracefully', () async {
      final integrationId = "health_connect";

      // Setup - throw exception
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            throw PlatformException(
              code: 'ERROR',
              message: 'Test error',
              details: 'Test error details',
            );
          });

      // Execute and verify exception is thrown
      expect(
        () => platform.connect(integrationId),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}
