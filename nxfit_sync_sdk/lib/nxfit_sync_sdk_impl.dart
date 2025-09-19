import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nxfit_sdk/models.dart';
import 'package:nxfit_sync_sdk/nxfit/models/local_integration_list.dart';
import 'package:rxdart/rxdart.dart';
import 'nxfit_sync_sdk_platform_interface.dart';
import 'package:nxfit_sdk/core.dart';
import 'package:logging/logging.dart';

@internal
class NxfitSyncSdkImpl extends NxfitSyncSdkPlatform {
  final _logger = Logger('com.neoex.nxfit.sync.bridge');
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
        _logger.fine("received update auth state for user: ${b.userId}");

        _authMessageChannel.send({
          "accessToken": b.accessToken,
          "userId": b.userId,
        });
      }),
    );

    _subs.add(
      _readyStateChannel.receiveBroadcastStream().listen((event) {
        if (event is bool) {
          _logger.fine("isReady state received from native: $event");
          _readyStateStream.value = event;
        }
        else {
          _logger.warning("Unknown state received from native: $event");
        }
      }, onError: (error) {
        _logger.severe("Error receiving ready state from native: $error");
      })
    );

    await _methodChannel.invokeMethod('configure', {
      "baseUrl": configProvider.baseUrl,
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
