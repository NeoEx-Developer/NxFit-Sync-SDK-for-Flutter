import 'dart:async';

import 'package:nxfit_sync_sdk/nxfit_sync_sdk.dart';
import 'package:workmanager/workmanager.dart';

import 'nxfit/auth_provider_impl.dart';
import 'nxfit/config_provider_impl.dart';

/// The background task dispatcher for Workmanager
/// This function is called by the Workmanager plugin when a worker task is triggered.
@pragma('vm:entry-point')
void nxfitSyncDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case "sync-all":
          final configProvider = ConfigProviderImpl();
          final authProvider = AuthProviderImpl();

          // We need credentials so that the worker can access the NXFit Web API
          // This may require the access token to be refreshed.
          authProvider.login();

          final nxfitSyncSdk = await NxfitSyncSdk.build(configProvider, authProvider);

          /// Wait until the SDK is ready before starting the sync process
          await for (final isReady in nxfitSyncSdk.isReady) {
            if (isReady) {
              print("Nxfit Sync Dispatcher: SDK is ready, starting sync");

              print("Nxfit Sync Dispatcher: Syncing exercise sessions");
              await nxfitSyncSdk.syncExerciseSessions();

              print("Nxfit Sync Dispatcher: Syncing daily metrics");
              await nxfitSyncSdk.syncDailyMetrics();

              print("Nxfit Sync Dispatcher: Sync completed");
              break;
            } else {
              print("Nxfit Sync Dispatcher: SDK is not ready, waiting...");
            }
          }
          break;

        default:
          // Handle unknown task types
          print("Nxfit Sync Dispatcher: Unknown task: $task");
          Future.error("Unknown task: $task");
          break;
      }
    } catch (e) {
      print("Nxfit Sync Dispatcher: Error executing task $task: $e");
      return Future.value(false);
    }

    return Future.value(true);
  });
}
