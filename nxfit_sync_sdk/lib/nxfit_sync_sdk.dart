import 'dart:io';

import 'package:nxfit_sdk/clients.dart';
import 'package:nxfit_sdk/core.dart';
import 'package:nxfit_sdk/models.dart';
import 'nxfit/exceptions/unavailable_integration_exception.dart';
import 'nxfit/exceptions/unsupported_integration_exception.dart';
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
class NxfitSyncSdk extends LocalIntegrationClient {
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
  static Future<NxfitSyncSdk> build(
    ConfigurationProvider configProvider,
    AuthProvider authProvider,
  ) async {
    final sdk = NxfitSyncSdk._(configProvider, authProvider);
    await NxfitSyncSdkPlatform.instance.init(authProvider, configProvider);
    return sdk;
  }

  /// Android-specific helper class.
  ///
  /// This property provides access to Android-specific functionality,
  /// such as generating URIs to launch the Google Play Store for Health Connect installation.
  /// It is `null` on non-Android platforms.
  final AndroidHelpers? androidHelpers = Platform.isAndroid
      ? AndroidHelpers()
      : null;

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
  @override
  Future<void> connect(String integrationIdentifier) async {
    _assertIntegrationIsAvailable(integrationIdentifier);

    return await NxfitSyncSdkPlatform.instance.connect(integrationIdentifier);
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
  @override
  Future<void> disconnect(String integrationIdentifier) async {
    _assertIntegrationIsAvailable(integrationIdentifier);

    return await NxfitSyncSdkPlatform.instance.disconnect(integrationIdentifier);
  }

  /// Gets all available local integrations on the current platform.
  ///
  /// This method retrieves a list of all local health integrations that can be
  /// used on the current platform, along with their availability status.
  /// Each integration includes its identifier, connection status, and current
  /// availability state (available, unavailable, or unsupported).
  ///
  /// Available integrations may include:
  /// - Apple HealthKit integration on iOS devices
  /// - Google Health Connect integration on Android devices
  ///
  /// Returns a [Future<List<LocalIntegration>>] containing all platform-supported
  /// integrations with their current availability status.
  ///
  /// Example:
  /// ```dart
  /// final integrations = await nxfitSyncSdk.getIntegrations();
  /// for (final integration in integrations) {
  ///   print('Integration: ${integration.identifier}');
  ///   print('Status: ${integration.availability}');
  ///
  ///   if (integration.availability == IntegrationAvailability.available) {
  ///     await nxfitSyncSdk.connect(integration.identifier);
  ///   } else if (integration.availability == IntegrationAvailability.unavailable) {
  ///     print('Setup required for ${integration.identifier}');
  ///   }
  /// }
  /// ```
  @override
  Future<List<LocalIntegration>> getIntegrations() async {
    return await NxfitSyncSdkPlatform.instance.getIntegrations();
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
  Future<void> purgeCache() async {
    return await NxfitSyncSdkPlatform.instance.purgeCache();
  }

  /// Triggers the sync operation to upload native health data to the NxFit platform.
  ///
  /// This method triggers the synchronization of workout/exercise sessions from
  /// the device's health store (HealthKit on iOS and Health Connect on Android)
  /// to the NxFit platform.
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
  ///   await nxfitSyncSdk.connect("health_connect");
  ///   await nxfitSyncSdk.syncExerciseSessions();
  ///   print('Exercise sync completed successfully');
  /// } catch (e) {
  ///   print('Exercise sync failed: $e');
  /// }
  /// ```
  Future<void> syncExerciseSessions() async {
    return await NxfitSyncSdkPlatform.instance.syncExerciseSessions();
  }

  /// Triggers the sync operation to upload daily health metrics to the NxFit platform.
  ///
  /// This method triggers the synchronization of daily aggregated health metrics
  /// (e.g., total steps, calories burned) from the device's health store
  /// (HealthKit on iOS and Health Connect on Android) to the NxFit platform.
  /// The sync process focuses on daily summaries rather than individual health samples.
  ///
  /// **Prerequisites:**
  /// - SDK must be connected (call [connect] first)
  /// - User must be authenticated with valid credentials
  /// - Required health permissions must be granted
  ///
  /// **Note:** On iOS with background sync enabled, manual calls to [syncDailyMetrics]
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
  ///   await nxfitSyncSdk.connect("health_connect");
  ///   await nxfitSyncSdk.syncDailyMetrics();
  ///   print('Daily metrics sync completed successfully');
  /// } catch (e) {
  ///   print('Daily metrics sync failed: $e');
  ///   }
  /// ```
  Future<void> syncDailyMetrics() async {
    return await NxfitSyncSdkPlatform.instance.syncDailyMetrics();
  }

  /// Stream that emits whether native sdk is ready to accept calls.
  @override
  Stream<bool> get isReady => NxfitSyncSdkPlatform.instance.isReady;

  /// Asserts that the specified integration is available on the current platform.
  ///
  /// This method checks the availability of the given integration and throws
  /// an appropriate exception if it is unsupported or unavailable.
  /// It is used internally before performing operations that require the integration.
  ///
  /// Parameters:
  /// - [integrationIdentifier]: The unique identifier of the integration to check.
  ///
  /// Throws:
  /// - [UnsupportedIntegrationException]: If the integration is not supported on this platform.
  /// - [UnavailableIntegrationException]: If the integration requires additional setup.
  Future<void> _assertIntegrationIsAvailable(
    String integrationIdentifier,
  ) async {
    final integrations = await NxfitSyncSdkPlatform.instance.getIntegrations();
    final integration = integrations
        .where((i) => i.identifier == integrationIdentifier)
        .singleOrNull;

    if (integration == null ||
        integration.availability == IntegrationAvailability.unsupported) {
      throw UnsupportedIntegrationException(integrationIdentifier);
    } else if (integration.availability ==
        IntegrationAvailability.unavailable) {
      throw UnavailableIntegrationException(integrationIdentifier);
    }
  }
}

/// Helper class for Android-specific functionality.
class AndroidHelpers {
  /// Provides a URI that may be used to launch the Google Play Store to the Health Connect app page.
  ///
  /// This URI can be used to prompt users to install Health Connect if it is not already installed on their device.
  /// Android devices prior to Android 14 (API level 34) do not have Health Connect pre-installed, so this URI is useful
  /// for guiding users to install it.
  ///
  /// Example usage:
  /// ```dart
  /// final uri = androidHelpers.getHealthConnectUri();
  /// await launchUrl(uri);
  /// ```
  Uri getHealthConnectUri() {
    final String healthConnectPackageName =
        "com.google.android.apps.healthdata";
    final String uriString =
        "market://details?id=$healthConnectPackageName&url=healthconnect%3A%2F%2Fonboarding";

    return Uri.parse(uriString);
  }
}
