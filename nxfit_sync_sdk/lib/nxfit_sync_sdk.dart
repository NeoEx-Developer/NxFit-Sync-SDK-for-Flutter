import 'package:nxfit_sdk/core.dart';
import 'nxfit_sync_sdk_platform_interface.dart';

/// Main interface for the NxFit Sync SDK.
/// 
/// This class provides seamless integration with NxFit's health data synchronization
/// services, bridging Flutter applications with native iOS and Android NxFit SDKs
/// to sync health and fitness data from device health stores (HealthKit on iOS and
/// Health Connect on Android) to the NxFit platform.
/// 
/// The SDK supports real-time sync monitoring and background sync capabilities on iOS and Android.
/// 
/// Example usage:
/// ```dart
/// final authProvider = AuthProviderImpl();
/// final configProvider = ConfigProviderImpl();
/// final nxfitSyncSdk = await NxfitSyncSdk.build(configProvider, authProvider);
///
/// await nxfitSyncSdk.connect();
/// await nxfitSyncSdk.sync();
/// ```
class NxfitSyncSdk {
  /// Configuration provider that supplies SDK configuration settings.
  /// 
  /// This provider is used to configure the NxFit SDK with necessary
  /// settings such as API endpoints, timeouts, and other platform-specific
  /// configuration parameters.
  final ConfigurationProvider configProvider;

  /// Authentication provider that supplies user credentials and tokens.
  /// 
  /// This provider is responsible for providing valid user authentication
  /// tokens and user IDs required for secure API access to the NxFit platform.
  final AuthProvider authProvider;

  /// Private constructor for internal use only.
  /// Use [NxfitSyncSdk.build] to create instances.
  NxfitSyncSdk._(this.configProvider, this.authProvider);

  /// Constructs a new instance of [NxfitSyncSdk].
  /// 
  /// Initializes the SDK with the provided [configProvider] and [authProvider].
  /// The SDK will automatically initialize the platform-specific implementation
  /// with these providers.
  /// 
  /// Parameters:
  /// - [configProvider]: Configuration provider for SDK settings
  /// - [authProvider]: Authentication provider for user credentials
  /// 
  /// Example:
  /// ```dart
  /// final sdk = await NxfitSyncSdk.build(
  ///   ConfigProviderImpl(),
  ///   AuthProviderImpl()
  /// );
  /// ```
  static Future<NxfitSyncSdk> build(ConfigurationProvider configProvider, AuthProvider authProvider) async {
    final sdk = NxfitSyncSdk._(configProvider, authProvider);
    await NxfitSyncSdkPlatform.instance.init(authProvider, configProvider);
    return sdk;
  }

  /// Connects the sync process to the native platform (HealthKit or Health Connect).
  /// 
  /// This method initializes the connection and prepares the SDK for data synchronization
  /// to the NxFit services. It should be called when the relevant local
  /// integration is being enabled by the user - iOS or Android.
  ///
  /// On iOS, this may trigger HealthKit authorization requests
  /// if not previously granted.
  /// 
  /// Returns a [Future] that completes when the connection is established.
  /// 
  /// Throws an exception if:
  /// - Authentication credentials are invalid
  /// - Network connectivity issues prevent connection
  /// - Platform-specific authorization is denied
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   await nxfitSyncSdk.connect();
  ///   print('Connected successfully');
  /// } catch (e) {
  ///   print('Connection failed: $e');
  /// }
  /// ```
  Future<void> connect() {
    return NxfitSyncSdkPlatform.instance.connect();
  }

  /// Disconnects the sync process from the native platform (HealthKit or Health Connnect).
  /// 
  /// This method safely disables the connection to NxFit services and
  /// performs necessary cleanup operations. Any ongoing sync operations
  /// will be cancelled. It should be called when a user wishes to disconnect
  /// the relevant local integration - iOS or Android.
  /// 
  /// Returns a [Future] that completes when the disconnection is complete.
  /// 
  /// Example:
  /// ```dart
  /// await nxfitSyncSdk.disconnect();
  /// print('Disconnected from NxFit services');
  /// ```
  Future<void> disconnect() {
    return NxfitSyncSdkPlatform.instance.disconnect();
  }

  /// Checks whether the SDK is currently connected to the native platform.
  /// 
  /// This method returns the current connection status without attempting
  /// to establish or modify the connection. It's useful for checking the
  /// connection state before performing sync operations.
  /// 
  /// Returns a [Future<bool>] that resolves to:
  /// - `true` if the SDK is connected and ready for sync operations
  /// - `false` if the SDK is disconnected or not initialized
  /// 
  /// Example:
  /// ```dart
  /// final isConnected = await nxfitSyncSdk.isConnected();
  /// if (isConnected) {
  ///   await nxfitSyncSdk.sync();
  /// } else {
  ///   await nxfitSyncSdk.connect();
  /// }
  /// ```
  Future<bool> isConnected() {
    return NxfitSyncSdkPlatform.instance.isConnected();
  }

  /// Purges all cached data from the SDK.
  /// 
  /// This method clears all locally cached sync data, including sync progress,
  /// temporary files, and cached health data samples. This operation is useful
  /// for troubleshooting sync issues or when you want to perform a clean sync
  /// from scratch.
  /// 
  /// **Warning**: This operation is irreversible and will remove all local
  /// sync progress. The next sync operation will need to re-process all data.
  /// 
  /// Returns a [Future] that completes when the cache has been purged.
  /// 
  /// Example:
  /// ```dart
  /// // Clear cache before a fresh sync
  /// await nxfitSyncSdk.purgeCache();
  /// await nxfitSyncSdk.sync();
  /// ```
  Future<void> purgeCache() {
    return NxfitSyncSdkPlatform.instance.purgeCache();
  }

  /// Triggers the sync operation to upload native health data to the NxFit platform.
  /// 
  /// This method triggers the synchronization of health and fitness data from
  /// the device's health store (HealthKit on iOS and Health Connect on Android)
  /// to the NxFit platform. The sync process includes both health samples
  /// (steps, heart rate, etc.) and workout/exercise data.
  /// 
  /// **Prerequisites:**
  /// - SDK must be connected (call [connect] first)
  /// - User must be authenticated with valid credentials
  /// - Required health permissions must be granted
  /// 
  /// **Note:** On iOS with background sync enabled, manual calls to [sync]
  /// are not necessary as data will be automatically synced in the background.
  /// 
  /// Returns a [Future] that completes when the sync operation finishes.
  /// 
  /// Throws an exception if:
  /// - SDK is not connected
  /// - Authentication fails
  /// - Health permissions are insufficient
  /// - Network errors occur during sync
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   await nxfitSyncSdk.connect();
  ///   await nxfitSyncSdk.sync();
  ///   print('Sync completed successfully');
  /// } catch (e) {
  ///   print('Sync failed: $e');
  /// }
  /// ```
  Future<void> sync() {
    return NxfitSyncSdkPlatform.instance.sync();
  }
}
