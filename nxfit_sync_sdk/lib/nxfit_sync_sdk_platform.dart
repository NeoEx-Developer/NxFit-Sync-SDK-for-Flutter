import 'package:nxfit_sdk/core.dart';
import 'package:nxfit_sdk/models.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'nxfit_sync_sdk_impl.dart';

abstract class NxfitSyncSdkPlatform extends PlatformInterface {
  /// Constructs a NxfitSyncSdkPlatform.
  NxfitSyncSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static NxfitSyncSdkPlatform _instance = NxfitSyncSdkImpl();

  /// The default instance of [NxfitSyncSdkPlatform] to use.
  ///
  /// Defaults to [NxfitSyncSdkImpl].
  static NxfitSyncSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NxfitSyncSdkPlatform] when
  /// they register themselves.
  static set instance(NxfitSyncSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<bool> get isReady;
  Future<void> init(AuthProvider authProvider, ConfigurationProvider configProvider);
  Future<void> connect(String integrationIdentifier);
  Future<void> disconnect(String integrationIdentifier);
  Future<List<LocalIntegration>> getIntegrations();
  Future<void> purgeCache();
  Future<void> syncExerciseSessions();
  Future<void> syncDailyMetrics();
}
