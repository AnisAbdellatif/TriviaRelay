import 'package:flutter/foundation.dart';

/// What this build calls itself, stamped in at build time.
///
/// A release build passes both from `pubspec.yaml` as `--dart-define`s, the same
/// pair Gradle stamps into the APK's manifest. Any other build (`flutter run`,
/// `flutter test`) leaves [appVersionCode] at 0, and that is what switches the
/// update check off: a build with no released version cannot be behind one.
const appVersion = String.fromEnvironment('APP_VERSION');
const appVersionCode = int.fromEnvironment('APP_VERSION_CODE');

/// Where the app looks for the newest release: the `android.json` published
/// beside the APK on the GitHub release. Passed by the release build; empty (no
/// update check) until there is a release to check against.
const updateManifestUrl = String.fromEnvironment('UPDATE_MANIFEST_URL');

/// Whether this build has to find its own updates.
///
/// Only a sideloaded Android APK does. The web app is reloaded from the relay,
/// a development build has no version to be behind, and a build with no
/// [updateManifestUrl] has nowhere to look.
///
/// `kIsWeb` is a compile-time constant, so the whole check folds away in the
/// web bundle.
bool get updatesSupported => selfUpdates(
  isWeb: kIsWeb,
  isAndroid: defaultTargetPlatform == TargetPlatform.android,
  versionCode: appVersionCode,
  manifestUrl: updateManifestUrl,
);

/// [updatesSupported] as a plain function, because the constants it reads are
/// fixed at compile time and a test cannot be four different builds.
bool selfUpdates({
  required bool isWeb,
  required bool isAndroid,
  required int versionCode,
  required String manifestUrl,
}) => !isWeb && isAndroid && versionCode > 0 && manifestUrl.isNotEmpty;
