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
  nxfit_sync_sdk: ^0.0.10
```

## Flutter setup

If using the sync SDK in conjuction to our main flutter SDK, the following example shows how to list
the integrations, including local integrations, and connect.

```dart
// Construct the SDKs & managers
_nxFitSdk = NxFit.build(_configProvider, _authProvider);
_nxfitSyncSdk = await NxfitSyncSdk.build(_configProvider, _authProvider);
_nxFitManagers = await NxFitManagers.build(
    _nxFitSdk,
    // The redirect scheme below needs to be registered with our service and is usually in the form
    // of a package or bundle id. Your app should be configured to handle this scheme else the redirect
    // will fail and a blank page displayed. You can optionally call
    // _nxFitManagers.integrationsManager.handleAuthorizeResponseFromUrl with the URL which will emit a
    // ConnectionEvent based on the response.
    baseRedirectUri: "com.your.scheme://",
    localSyncClient: _nxfitSyncSdk
);

// Listen to & display emitted integrations. Integrations are automatically emitted once
// the user is authenticated. The emitted list of integrations includes connected, 
// disconnected, remote and local integrations. Local integrations included are those those
// which are natively supported - e.g. HealthKit on iOS devices and Health Connect on Android devices.
_subs.add(_nxFitManagers.integrationsManager.integrations.listen((integrations) {
    setState(() {
        _integrations = integrations.toList();
    });
}));

// Connect to an integration in the list, if remote then the URL will be launched.
Future<void> connect(IntegrationModel integration) async {
    await _nxFitManagers.integrationsManager.connect(integration.identifier,  (url) async {
        launchUrl(url);
    });

    //TODO: Need to handle the redirect or browser close event
    await _nxFitManagers.integrationsManager.refreshIntegrations();
}

// Disconnect a connected integration in the list.
Future<void> disconnect(IntegrationModel integration) async {
    // Should ensure that the integration is connected.
    // integration.isConnected

    await _nxFitManagers.integrationsManager.disconnect(integration.identifier);
    await _nxFitManagers.integrationsManager.refreshIntegrations();
}
```

## Android setup

For now the Android component of the plugin provides access only to Google Health Connect.

### AndroidManifest.xml

Health Connect permissions must be declared in the `AndroidManifest.xml` file, failing to do so will prevent the permissions request activity from being launched. You should only
declare the permissions you require as each one of them will need justification on Google Play when you submit the app for review. Note that only *READ* permissions are required
here as we do not support writing data to Health Connect. 

The `READ_HEALTH_DATA_IN_BACKGROUND` permission is only required if you intend to read Health Connect data in the background, such as in a background service or worker.

The `READ_EXERCISE` permission is only required if you want to read exercise data.

Note that currenly location records are not supported due to their peculiar permission requirements.

The following is a list of all the permissions associated with the Health Connect record types supported by the plugin. Pick and choose the ones you require and copy them into
your `AndroidManifest.xml` file.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.health.READ_HEALTH_DATA_IN_BACKGROUND" />

    <uses-permission android:name="android.permission.health.READ_ACTIVE_CALORIES_BURNED" />
    <uses-permission android:name="android.permission.health.READ_BASAL_METABOLIC_RATE" />
    <uses-permission android:name="android.permission.health.READ_BLOOD_PRESSURE" />
    <uses-permission android:name="android.permission.health.READ_BODY_FAT" />
    <uses-permission android:name="android.permission.health.READ_BODY_TEMPERATURE" />
    <uses-permission android:name="android.permission.health.READ_BODY_WATER_MASS" />
    <uses-permission android:name="android.permission.health.READ_BONE_MASS" />
    <uses-permission android:name="android.permission.health.READ_CYCLING_PEDALING_CADENCE" />
    <uses-permission android:name="android.permission.health.READ_DISTANCE" />
    <uses-permission android:name="android.permission.health.READ_ELEVATION_GAINED" />
    <uses-permission android:name="android.permission.health.READ_EXERCISE" />
    <uses-permission android:name="android.permission.health.READ_FLOORS_CLIMBED" />
    <uses-permission android:name="android.permission.health.READ_HEART_RATE" />
    <uses-permission android:name="android.permission.health.READ_HEART_RATE_VARIABILITY" />
    <uses-permission android:name="android.permission.health.READ_HEIGHT" />
    <uses-permission android:name="android.permission.health.READ_HYDRATION" />
    <uses-permission android:name="android.permission.health.READ_LEAN_BODY_MASS" />
    <uses-permission android:name="android.permission.health.READ_OXYGEN_SATURATION" />
    <uses-permission android:name="android.permission.health.READ_POWER" />
    <uses-permission android:name="android.permission.health.READ_RESPIRATORY_RATE" />
    <uses-permission android:name="android.permission.health.READ_RESTING_HEART_RATE" />
    <uses-permission android:name="android.permission.health.READ_SLEEP" />
    <uses-permission android:name="android.permission.health.READ_SPEED" />
    <uses-permission android:name="android.permission.health.READ_STEPS" />
    <uses-permission android:name="android.permission.health.READ_STEPS_CADENCE" />
    <uses-permission android:name="android.permission.health.READ_TOTAL_CALORIES_BURNED" />
    <uses-permission android:name="android.permission.health.READ_VO2_MAX" />
    <uses-permission android:name="android.permission.health.READ_WEIGHT" />
    <uses-permission android:name="android.permission.health.READ_WHEELCHAIR_PUSHES" />
</manifest>
```

### FlutterFragmentActivity
Ensure that the `MainActivity` extends `FlutterFragmentActivity` to support permissions requests required by Health Connect. Typically when creating 
a Flutter app with Android embedding v2, the MainActivity extends `FlutterActivity` by default. Change it to extend `FlutterFragmentActivity` instead.

``` kotlin
        // YourApp/android/app/src/main/kotlin/com/yourcompany/yourapp/MainActivity.kt
        import io.flutter.embedding.android.FlutterFragmentActivity

        class MainActivity : FlutterFragmentActivity()
```

### Setting up access to GitHub Packages
The NXFit Health Connect SDK which is used by this plugin is currently hosted on GitHub Packages. Follow these steps to add the SDK to your build:

#### Create GitHub Access Token
GitHub provides maven packages only through authenticated connections.
- Login to GitHub (create an account if needed).
- Go to **Settings** &#8594; **Developer Settings** &#8594; **Personal access tokens** &#8594; **Tokens (Classic)**
- Click on **Generate new token (Classic)**
- Give the new token a meaningful name and the only scope required is **read:packages**.
- Since this token only requires **read:packages** set the expiration to whatever you feel comfortable with, however for this token scope *No Expiration* should be fine.
- Once the required scope is checked, click **Generate token**.
- Copy the generated access token and record it somewhere safe. You'll need it when updating the *build.gradle* files.

#### Add the NXFit GitHub Packages repository to your gradle build files
- Using the access token generated in the prior step, add the following maven repository to *settings.gradle* file:

``` kotlin
        // YouApp/android/build.gradle.kts

        allprojects {
            repositories {
                google()
                mavenCentral()
        
                maven {
                    val githubUser = "YOUR_GITHUB_USERNAME"
                    val githubToken = "YOUR_GITHUB_ACCESS_TOKEN"
        
                    // NOTE, if you placed your github credentials into the global gradle.properties file,
                    // you can read them as shown:
                    //   val githubUser =  project.findProperty("GITHUB_USER") as? String
                    //   val githubToken = project.findProperty("GITHUB_TOKEN") as? String
                    // See https://docs.gradle.org/current/userguide/build_environment.html#sec:gradle
                    // Be sure to never commit your credentials to source control!
        
                    name = "GitHubPackages"
                    url = uri("https://maven.pkg.github.com/NeoEx-Developer/NXFit-SDK-for-Android")
        
                    credentials {
                        username = githubUser
                        password = githubToken
                    }
                }
            }
        }
```

## Getting started with Health Connect (Android only) ##

Before **nxfit_sync_sdk** can use Google's Health Connect API on Android, two requirements must be met:
- Google Health Connect must be installed on the device.
- Permissions must be granted to your app to read health data.
 
#### Health Connect Availability
Google Health Connect must be installed on the device. Health Connect is supported only on devices running Android 9+ (API level 28).
On devices running Android 14+ (API level 34), Health Connect comes pre-installed. For devices running Android 9 to Android 13, users must
download the Health Connect app from the Google Play Store if it hasn't already been installed.

To check if Health Connect is available on the device, the **nxfit_sync_sdk** provides a list of local integrations along with their availability. Here's an example of how to 
check if Health Connect is available:

``` dart
    final integrations = await nxfitSyncSdk.getIntegrations();
    final healthConnectIntegration = integrations?.firstWhere(
        (integration) => integration.identifier == "health_connect",
        orElse: () => null,
    );
    final healthConnectAvailability = healthConnectIntegration?.availability ?? IntegrationAvailability.unsupported;

    // True when Health Connect is available and ready to use.
    final isHealthConnectAvailable = healthConnectAvailability == IntegrationAvailability.available;

    // True when Health Connect requires an update or installation.
    final isHealthConnectUnavailable = healthConnectAvailability == IntegrationAvailability.unavailable;

    // True when Health Connect is not supported on this device.
    final isHealthConnectUnsupported = healthConnectAvailability == IntegrationAvailability.unsupported;
```

If Google Health Connect is unavailable (ie. it is not installed or requires an update), the user will be required to install it before connecting. It is recommended to check
for Health Connect availability before calling `connect("health_connect")`. To install or update Health Connect, the user must do so using the Google Play Store. To facilitate this,
**nxfit_sync_sdk** provides the `AndroidHelpers` class via the `androidHelpers` property (only on Android). The `AndroidHelpers` class provides the `getHealthConnectUri()` method which
returns a `Uri` that can be used to launch the Google Play Store to the Health Connect app's page. Example:

``` dart
    final androidHelpers = nxfitSyncSdk.androidHelpers;
    if (androidHelpers != null) {
        final uri = androidHelpers.getHealthConnectUri();

        // The url_launcher package may be used to launch the Play Store (https://pub.dev/packages/url_launcher):
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
```

The **nxfit_sync_sdk** will automatically check if Health Connect is installed when `connect("health_connect")` or `disconnect("health_connect)` is
called. In this case, if Health Connect is unavailable or unsupported, the following exceptions will be thrown:
- UnavailableIntegrationException
- UnsupportedIntegrationException

**Note**: The `syncExerciseSessions()`, `syncDailyMetrics()` and `purgeCache()` functions perform their operations on all connected integrations, so they do not throw the above
listed exceptions.

#### Health Connect Permissions
Permissions must be granted to your app to read Health Connect data. See the [Health Connect documentation](https://developer.android.com/guide/health-and-fitness/health-connect/get-started)
for more details.

The **nxfit_sync_sdk** will automatically request Health Connect permissions from the user when `connect("health_connect")` is called. Once a user has granted permissions, they will
not be asked again unless the app is uninstalled or the user revokes permissions through the system settings. Note that users can permanently deny permissions by selecting the
"Don't ask again" option when the permission dialog is shown. In this case, your app will not be able to request permissions again and the user must manually enable permissions
through system settings. On newer versions of Android, if a user denies permissions multiple times, the system may automatically prevent further permission requests.

As mentioned above, the Health Connect record and background read permissions must be declared in your `AndroidManifest.xml` for the Android project. On top of that, a query must be declared in the
`AndroidManifest.xml` to allow the Sync SDK to check if Health Connect is available. However, this is automatically merged into your app's manifest to allow querying the state
of Health Connect on the device. An additional query is merged to allow looking up apps that have reported data to Health Connect based on their package ID. Here is what will be
merged into your app's manifest (You do not need to add them):

``` xml
    // Merge'd from the NXFit Health Connect SDK's AndroidManifest.xml.
    <manifest xmlns:android="http://schemas.android.com/apk/res/android">
        <queries>
            <!-- Check if Health Connect is installed -->
            <package android:name="com.google.android.apps.healthdata" />
    
            <!-- Allows calls to PackageManager.getPackageInfo(). This is
                 used to get the app name based on the package ID reported
                 by Health Connect. -->
            <intent>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent>
        </queries>

        .....
   
    </manifest>
```

#### Health Connect requires a Privacy Policy

Your Android manifest needs to have an Activity that displays your app's privacy policy, which is your app's rationale of the requested permissions, describing how the user's data is used and handled.

Declare this activity to handle the `ACTION_SHOW_PERMISSIONS_RATIONALE` intent where it is sent to the app when the user clicks on the privacy policy link in the Health Connect permissions screen.

```xml
    <application>
        ...
        <!-- For supported versions through Android 13, create an activity to show the rationale
             of Health Connect permissions once users click the privacy policy link. -->
        <activity
            android:name=".PermissionsRationaleActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE" />
            </intent-filter>
        </activity>
    
        <!-- For versions starting Android 14, create an activity alias to show the rationale
             of Health Connect permissions once users click the privacy policy link. -->
        <activity-alias
            android:name="ViewPermissionUsageActivity"
            android:exported="true"
            android:targetActivity=".PermissionsRationaleActivity"
            android:permission="android.permission.START_VIEW_PERMISSION_USAGE">
            <intent-filter>
                <action android:name="android.intent.action.VIEW_PERMISSION_USAGE" />
                <category android:name="android.intent.category.HEALTH_PERMISSIONS" />
            </intent-filter>
        </activity-alias>
        ...
    </application>
```

**NOTE**: Without this declared in your manifest, Health Connect will not show the permissions dialog to the user and your app will not be able to request Health Connect permissions.

For details see the [offical documentation](https://developer.android.com/health-and-fitness/guides/health-connect/develop/get-started#show-privacy-policy).

Neo eX has it's privacy policy available at: https://www.neoex.io/privacy-policy


## iOS setup

### iOS Swift Package Manager (SPM)

Swift Package Manager will need to be enabled for your project as this package utilises SPM.

See [here](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers) for more details.

## Usage

The below example shows how to use the sync SDK directly.

```dart
// Initialize the SDK
final authProvider = AuthProviderImpl();
final configProvider = ConfigProviderImpl();
final nxfitSyncSdk = await NxfitSyncSdk.build(configProvider, authProvider);
final integrationId = "apple"; // Only on iOS

// Perform connect & sync operations
// If using background sync, calls to syncExerciseSessions or
// syncDailyMetrics() is not necessary.
// On initial connection and subsequent instances of the
// NxfitSyncSdk, the sync processes will run automatically
// when the AuthProvider emits an authenticated user state.
await nxfitSyncSdk.connect(integrationId);

// You can manually trigger the sync processes at any time
// after the integration is connected.
await nxfitSyncSdk.syncExerciseSesssions();
await nxfitSyncSdk.syncDailyMetrics();
```

### For iOS background sync

If you wish to enable background sync, allowing workouts and samples to be delivered to your app, you'll need to include the below snippet in your AppDelegate.
Background delivery requires a user id and valid access token to send data to the NXFit platform.

```swift
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {  
        // Optional logging setup using swift-log.    
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = Logger.Level.trace
            return handler
        }

        GeneratedPluginRegistrant.register(with: self)

        // Include a similar block after the plugins are registered.
        // The access token and user id must be accessible to the native
        // platform in the background. 
        Task {
            if let (userId, accessToken) = YourSwiftAuthImpl.getAuth() {
                NXFitSyncBackground.enableHealthKitBackgroundDelivery(configProviderImpl, userId: userId, accessToken: accessToken)
            }
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

### For Android background sync

Health Connect does not currently support background delivery of health data. Instead, the app must periodically call `syncExerciseSessions()` and `syncDailyMetrics()` to sync data.
The recommended approach is to use Android's WorkManager to schedule periodic syncs. See the 
[WorkManager documentation](https://developer.android.com/topic/libraries/architecture/workmanager) for more details.

For Flutter apps, the [workmanager](https://pub.dev/packages/workmanager) package can be used to schedule background tasks. Once the workmanager package is added to your
`pubspec.yaml`, you'll need to create a work dispatcher that calls the `syncExerciseSessions()` and `syncDailyMetrics()` methods of the **nxfit_sync_sdk**. Then, you can schedule 
periodic work using the workmanager API.

**NOTE**: The work dispatcher function requires it's own access to the NXFit API credentials (user id and access token) to create an instance of `NxfitSyncSdk`.
This is because the work dispatcher runs in a separate isolate and does not share state with the main app. This means that an access token may need to be refreshed since the
worker can run in the background without the main app running.

``` dart
/// This function is the entry point for the WorkManager background task.
/// It must be a top-level function and annotated with @pragma('vm:entry-point').
/// See https://pub.dev/packages/workmanager for more details.
/// Make sure to initialize the Workmanager in your main() function before calling runApp().
@pragma('vm:entry-point')
void nxfitSyncDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case "sync-all":
          final configProvider = ConfigProviderImpl();
          final authProvider = AuthProviderImpl();

          // We need credentials so that the worker can access the NXFit Web API.
          // This may require the access token to be refreshed.
          authProvider.login();

          final nxfitSyncSdk = await NxfitSyncSdk.build(configProvider, authProvider);

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
      }
    } catch (e) {
      print("Nxfit Sync Dispatcher: Error executing task $task: $e");
      return Future.value(false);
    }

    return Future.value(true);
  });
}
```

``` dart
/// In your main.dart file, initialize the Workmanager before calling runApp().
/// This ensures that the Workmanager is properly set up to handle background tasks.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(nxfitSyncDispatcher);

  runApp(const MyApp());
}
```

When the user chooses to connect to Health Connect, you can register a periodic task to sync data every 15 minutes (the minimum interval allowed by WorkManager). 

```dart
  /// Call this function after the user connects to Health Connect. This
  /// will register a periodic task to sync data every 15 minutes, even in the background.
  void registerWorker() {
    final uniqueName = "sync-all-task";

    Workmanager().registerPeriodicTask(
        uniqueName, "sync-all",
        frequency: Duration(minutes: 15),
        initialDelay: Duration(seconds: 0),
        existingWorkPolicy: ExistingWorkPolicy.replace,
    );
    print("Worker Registered");
  }
```

## Platform Requirements

- **iOS**: iOS 16.0+, HealthKit entitlements required. Background delivery required if used.
- **Android**: API level 26+
- **Flutter**: 3.3.0+

## Dependencies

- `nxfit_sdk`: Core NxFit SDK components
- `rxdart`: Reactive stream management
- `logging`: Comprehensive logging support
