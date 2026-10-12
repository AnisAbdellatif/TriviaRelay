import java.net.URI
import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is not done here. Gradle runs plugins and downloads code this
// repository does not control, so the release key is never where Gradle can see it:
// `scripts/ci.sh apk` builds the release APK unsigned, and `scripts/ci.sh sign` signs it
// afterwards with only the Android build-tools' `zipalign` and `apksigner` (in CI, in
// another job on another machine). See README.md, "Releasing the Android app".
//
// Only the release path — `scripts/ci.sh apk`, then `scripts/ci.sh sign` — builds the
// app people install, and it says so with TRIVIA_RELAY_RELEASE_BUILD=1. Everything else
// (`flutter run`, a hand-built `flutter build apk`) is a development build: a different
// application id and name, so it installs beside the GitHub release instead of
// colliding with it. A collision is not an upgrade either way: the signatures differ,
// so Android would refuse it, or make you uninstall the real app first.
val releaseBuild = System.getenv("TRIVIA_RELAY_RELEASE_BUILD") == "1"

// The relay's host, for the invite links the app opens (AndroidManifest.xml): read from
// the SERVER_URL the build is given (`--dart-define`, which Flutter hands Gradle as
// base64 in `dart-defines`), so the links and the relay the app talks to are one. A
// build without one (`flutter run`) claims an address that can't exist.
val inviteLinkHost: String = run {
    val defines = (project.findProperty("dart-defines") as String?).orEmpty()
    defines.split(",").filter { it.isNotBlank() }
        .map { String(Base64.getDecoder().decode(it), Charsets.UTF_8) }
        .firstOrNull { it.startsWith("SERVER_URL=") }
        ?.removePrefix("SERVER_URL=")
        ?.let { runCatching { URI(it).host }.getOrNull() }
        ?.takeIf { it.isNotBlank() }
        ?: "relay.invalid"
}

android {
    namespace = "com.triviarelay.trivia_relay"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.triviarelay.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. `scripts/ci.sh apk` reads the same
        // line and passes it to Dart as APP_VERSION_CODE, so what the app believes it
        // is and what Android installs it as cannot drift apart.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        if (!releaseBuild) applicationIdSuffix = ".dev"
        manifestPlaceholders["appLabel"] = if (releaseBuild) "Trivia Relay" else "Trivia Relay Dev"
        manifestPlaceholders["inviteLinkHost"] = inviteLinkHost

        // `--target-platform` in `scripts/ci.sh apk` picks which ABIs Flutter's own
        // engine and snapshot are built for. This says the same thing to everything
        // else — see the packaging block below for why both are needed. Release only:
        // a development build has to keep x86_64 so `flutter run` works on an emulator.
        if (releaseBuild) ndk { abiFilters += listOf("armeabi-v7a", "arm64-v8a") }
    }

    // Native libraries that arrive inside a plugin's AAR are already built, so
    // `abiFilters` does not reach them: an x86_64 `libdartjni.so` was still being
    // packaged with no `libflutter.so` beside it. An x86_64 device reads that
    // directory as "this APK supports me", installs, and then crashes on launch for
    // want of the engine. Dropping the directory is what makes the APK say arm-only,
    // so such a device declines it cleanly instead. Release only, like `abiFilters`.
    if (releaseBuild) {
        packaging {
            jniLibs {
                excludes += setOf("**/x86/**", "**/x86_64/**", "**/mips*/**")
            }
        }
    }

    buildTypes {
        release {
            // The release build is left unsigned for `scripts/ci.sh sign` (above). Anything
            // else built as release (`flutter run --release`) is signed with the debug key,
            // so it still installs for someone who has no release key.
            signingConfig = if (releaseBuild) null else signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
