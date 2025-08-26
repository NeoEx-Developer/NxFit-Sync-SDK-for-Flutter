import 'dart:async';
import 'package:flutter/services.dart';
import 'nxfit_sync_sdk_platform_interface.dart';
import 'package:nxfit_sdk/core.dart';
import 'package:logging/logging.dart';

class NxfitSyncSdkImpl extends NxfitSyncSdkPlatform {
  final logger = Logger('com.neoex.nxfit.sync.bridge');
  final methodChannel = const MethodChannel('com.neoex.sdk');
  final authMessageChannel = const BasicMessageChannel<Object?>(
    'com.neoex.sdk/authProvider',
    JSONMessageCodec(),
  );
  late AuthProvider provider;
  final List<dynamic> _subs = [];

  @override
  Future<void> init(AuthProvider authProvider, ConfigurationProvider configProvider) async {
    provider = authProvider;

    _subs.add(
      provider.authState.listen((b) {
        logger.fine("received update auth state for user: ${b.userId}");

        authMessageChannel.send({"accessToken": b.accessToken, "userId": b.userId});
      }),
    );

    await methodChannel.invokeMethod('configure', {
      "baseUrl": configProvider.baseUrl,
    });
  }

  @override
  Future<void> connect() async {
    await methodChannel.invokeMethod('connect');
  }

  @override
  Future<void> disconnect() async {
    await methodChannel.invokeMethod('disconnect');
  }

  @override
  Future<bool> isConnected() async {
    final isConnected = await methodChannel.invokeMethod<bool>('isConnected');
    return isConnected ?? false;
  }

  @override
  Future<void> purgeCache() async {
    await methodChannel.invokeMethod('purgeCache');
  }

  @override
  Future<void> sync() async {
    await methodChannel.invokeMethod('sync');
  }
}
