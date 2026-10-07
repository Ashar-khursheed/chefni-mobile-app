plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.chefni_flutter_app"
    // Pinned to what is actually installed on this machine — this host cannot
    // download SDK components (its TLS corrupts large artifact downloads), so
    // letting Flutter pick a version it would have to fetch fails the build.
    compileSdk = 37
    buildToolsVersion = "36.0.0"
    ndkVersion = flutter.ndkVersion

    // The installed platform reports a malformed API level ("37.0"), which the
    // lint task cannot resolve. Lint is not part of producing the APK, so it
    // is skipped rather than blocking the build.
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.chefni_flutter_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")

            // R8 resolves the platform through the SDK manager, which fails on
            // this host's non-standard platform install. Shrinking only affects
            // APK size, so it is off until the SDK is reinstalled cleanly.
            isMinifyEnabled = false
            isShrinkResources = false
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
