# Build Fix & APK Generation Plan

The current build is failing due to a Gradle/AGP version mismatch and environmental issues on the host (TLS corruption and Android location service errors). This plan aims to stabilize the build environment and successfully generate a debug APK.

## User Review Required

> [!IMPORTANT]
> The build is currently failing because of very experimental Gradle/AGP versions (9.x). We will revert to stable versions (8.x) that are compatible with Flutter 3.44.
>
> Your `gradle.properties` contains specific flags to bypass a hardware issue with AES-NI. We will keep those but adjust them to allow stable artifact downloads.

## Proposed Changes

### Build Configuration

#### [MODIFY] [gradle-wrapper.properties](file:///F:/chefni-mobile-app/chefni_flutter_app/android/gradle/wrapper/gradle-wrapper.properties)
* Revert to Gradle 8.10.2 (Stable).

#### [MODIFY] [settings.gradle.kts](file:///F:/chefni-mobile-app/chefni_flutter_app/android/settings.gradle.kts)
* Revert AGP to 8.7.2 (Stable).
* Revert Kotlin to 2.0.21 (Stable).

#### [MODIFY] [gradle.properties](file:///F:/chefni-mobile-app/chefni_flutter_app/android/gradle.properties)
* Add `android.overridePathCheck=true` to fix the `AndroidLocationsBuildService` error on Windows.
* Adjust TLS settings to ensure Gradle can download artifacts without `bad_record_mac` errors.

## Verification Plan

### Automated Steps
1. Run `flutter clean` to wipe stale build artifacts.
2. Run `flutter pub get` to ensure dependencies are fresh.
3. Run `flutter build apk --debug` to generate the APK.

### Manual Verification
* Once the build succeeds, the APK will be available at `build/app/outputs/flutter-apk/app-debug.apk`.
