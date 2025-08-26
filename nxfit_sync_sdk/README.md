# nxfit_sync_sdk

*NxFit Sync SDK for Flutter* provides seamless integration with NxFit's health data synchronization services. This plugin bridges Flutter applications with native iOS and Android NxFit SDKs to sync health and fitness data from device health stores (HealthKit on iOS and Health Connect on Android) to the NxFit platform.

## Features

- **Cross-platform support**: Native iOS and Android implementations for HealthKit and Health Connection respectively.
- **Real-time sync monitoring**: Stream-based sync state updates with detailed progress tracking
- **Health data synchronization**: Automatically syncs samples and workouts from device health stores
- **Authentication integration**: Seamless auth provider integration for secure API access
- **Background sync support**: iOS background delivery capabilities for continuous data sync

## Key Components

### Core Classes
- `NxfitSyncSdk` - Main plugin interface

## Add NxFit Sync SDK to your project

In your project's `pubspec.yaml` file
* Add the latest version of *NxFit Sync SDK* to your *dependencies*.

```yaml
# pubspec.yaml

dependencies:
  nxfit_sync_sdk: ^0.0.1
```

### iOS Swift Package Manager (SPM)

Swift Package Manager will need to be enabled for your project as this package utilises SPM.

See [here](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers) for more details.

## Usage

```dart
// Initialize the SDK
final authProvider = AuthProviderImpl();
final configProvider = ConfigProviderImpl();
final nxfitSyncSdk = await NxfitSyncSdk.build(configProvider, authProvider);

// Perform connect & sync operations
// If using background sync, a call to sync() is not necessary.
await nxfitSyncSdk.connect();
await nxfitSyncSdk.sync();
```

### For iOS background sync

If you wish to enable background sync, allowing workouts and samples to be delivered to your app, you'll need to include the below snippet in your AppDelegate.
Background delivery requires a user id and valid access token to send data to the NXFit platform.

```swift
let configProvider = ConfigProviderImpl()
let userId = auth.userId
let accessToken = auth.accessToken

NXFitSyncBackground.enableHealthKitBackgroundDelivery(configProvider, userId: userId, accessToken: accessToken)
```

## Platform Requirements

- **iOS**: iOS 16.0+, HealthKit entitlements required. Background delivery required if used.
- **Android**: API level 21+
- **Flutter**: 3.3.0+

## Dependencies

- `nxfit_sdk`: Core NxFit SDK components
- `rxdart`: Reactive stream management
- `logging`: Comprehensive logging support
