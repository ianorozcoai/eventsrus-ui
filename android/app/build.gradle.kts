plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Push notifications (Firebase Cloud Messaging) - applied only once
// google-services.json (downloaded from the Firebase console, see
// PushNotificationService's own doc comment) actually exists here, since
// the plugin itself hard-fails the build the moment it's applied without
// that file. Until then this is a silent no-op and the rest of the app
// behaves exactly as it does today.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

android {
    namespace = "com.eventsrus.eventsrus_ui"
    // Pinned explicitly (not just flutter.compileSdkVersion, which currently
    // resolves to 34) - the file_picker plugin's flutter_plugin_android_lifecycle
    // dependency requires compiling against API 36+.
    compileSdk = maxOf(flutter.compileSdkVersion, 36)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications requires this (its AAR metadata
        // declares the requirement, enforced at build time by
        // checkDebugAarMetadata) - without it, the build fails outright.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.eventsrus.eventsrus_ui"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Pinned explicitly (not just flutter.minSdkVersion) because
        // google_sign_in_android requires minSdk 24 - currently matches
        // Flutter's own default by coincidence; pinning it means a future
        // Flutter upgrade that changes that default can't silently break
        // native Google Sign-In.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            // Local dev installs only need the architecture of whatever
            // device/emulator is actually running the build - restricting
            // to arm64-v8a (every modern phone/emulator image) roughly
            // halves the debug APK's install transfer size. Release stays
            // multi-arch below for real Play Store distribution.
            ndk {
                abiFilters += "arm64-v8a"
            }
        }
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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

dependencies {
    // Pairs with isCoreLibraryDesugaringEnabled above.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
