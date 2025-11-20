## 0.0.10
- Added support for sleep samples on iOS (via the native iOS SDK).

## 0.0.9
- Upgraded nxfit_sdk reference to 0.3.1 which fixes an issue where the list of integrations was not being properly updated.

## 0.0.8
- BREAKING: Health Connect permissions are no longer automatically merged into the AndroidManifest.xml file of the consuming app. This means that apps that make use of Health Connect must delcare all the permissions that pertain to their app. This include requesting for background processing if using a background worker or service.

## 0.0.7

- Introduced synchronization for `ActiveCaloriesBurnedRecord` and `BasalMetabolicRateRecord`.
- Energy properties are now names as kilocalories instead of calories. The values were always in kilocalories but now the name reflects the actual unit used.

## 0.0.6

The HTTP log level and the logger level set by the ConfigurationProvider is now respected by the sync process (done via the native iOS/Android SDK).

## 0.0.5

- The Android component of the SDK now depends on nxfit-sdk & nxfit-sdk-healthconnect version 9.0.7. This fixes an issue where some metrics associated with exercises were not properly synced with the NxFit service. The amount of logging has also been reduced substantially.

## 0.0.4

- The Android component of the SDK now depends on nxfit-sdk & nxfit-sdk-healthconnect version 9.0.6. This fixes an issue with syncing steps and
  heart rate data. Also fixed an issue where the application ID and application name was not properly set when syncing.

## 0.0.3

- Added Flutter example app to demonstrate how the SDK can be used in a Flutter application.

## 0.0.2

- Added support for Health Connect integration on Android. The Android component of the SDK depends the nxfit-sdk &
nxfit-sdk-healthconnect version 9.0.5.

## 0.0.1

- Initial release with iOS sync integration
