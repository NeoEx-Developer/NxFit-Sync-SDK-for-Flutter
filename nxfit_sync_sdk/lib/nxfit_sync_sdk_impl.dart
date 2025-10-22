import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nxfit_sdk/models.dart';
import 'package:nxfit_sync_sdk/nxfit/models/local_integration_list.dart';
import 'package:rxdart/rxdart.dart';
import 'nxfit_sync_sdk_platform.dart';
import 'package:nxfit_sdk/core.dart';
import 'package:nxfit_sdk/src/logging/nxfit_logger.dart';

@internal
class NxfitSyncSdkImpl extends NxfitSyncSdkPlatform {
  final _methodChannel = const MethodChannel('com.neoex.sdk');
  final _authMessageChannel = const BasicMessageChannel<Object?>(
    'com.neoex.sdk/authProvider',
    JSONMessageCodec(),
  );
  final _readyStateChannel = const EventChannel('com.neoex.sdk/readyState');
  final _readyStateStream = BehaviorSubject<bool>.seeded(false);
  late AuthProvider _provider;
  final List<dynamic> _subs = [];

  @override
  Future<void> init(
    AuthProvider authProvider,
    ConfigurationProvider configProvider,
  ) async {
    _provider = authProvider;

    _subs.add(
      _provider.authState.listen((b) {
        logger.fine("received update auth state for user: ${b.userId}");

        _authMessageChannel.send({
          "accessToken": b.accessToken,
          "userId": b.userId,
        });
      }),
    );

    _subs.add(
      _readyStateChannel.receiveBroadcastStream().listen((event) {
        if (event is bool) {
          logger.fine("isReady state received from native: $event");
          _readyStateStream.value = event;
        }
        else {
          logger.warning("Unknown state received from native: $event");
        }
      }, onError: (error) {
        logger.severe("Error receiving ready state from native: $error");
      })
    );

    await _configure(configProvider);
  }

  Future<void> _configure(ConfigurationProvider configProvider) async {
    logger.config("baseUrl: ${configProvider.baseUrl}");
    logger.config("httpLoggerLevel: ${configProvider.httpLoggerLevel.name}");
    logger.config("minLogLevel: ${configProvider.minLogLevel.name}");
    logger.config("NxfitSyncSdk: ${configProvider.connectTimeoutSeconds}");

    await _methodChannel.invokeMethod('configure', {
      "baseUrl": configProvider.baseUrl,
      "httpLoggerLevel": configProvider.httpLoggerLevel.name,
      "minLogLevel": configProvider.minLogLevel.name,
    });
  }

  @override
  Stream<bool> get isReady => _readyStateStream.asBroadcastStream().distinct();

  @override
  Future<void> connect(String integrationIdentifier) async {
    await _methodChannel.invokeMethod('connect', {
      "integrationIdentifier": integrationIdentifier,
    });
  }

  @override
  Future<void> disconnect(String integrationIdentifier) async {
    await _methodChannel.invokeMethod('disconnect', {
      "integrationIdentifier": integrationIdentifier,
    });
  }

  @override
  Future<List<LocalIntegration>> getIntegrations() async {
    final json = await _methodChannel.invokeMethod<String>('getIntegrations');

    if (json != null) {
      return LocalIntegrationList.fromJson(jsonDecode(json)).integrations ?? [];
    } else {
      throw Exception('Failed to get integrations');
    }
  }

  @override
  Future<void> purgeCache() async {
    await _methodChannel.invokeMethod('purgeCache');
  }

  @override
  Future<void> syncExerciseSessions() async {
    await _methodChannel.invokeMethod('syncExerciseSessions');
  }

  @override
  Future<void> syncDailyMetrics() async {
    await _methodChannel.invokeMethod('syncDailyMetrics');
  }
}
