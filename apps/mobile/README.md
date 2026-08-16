# CareMate mobile

Android-first Flutter client for CareMate. The current foundation provides the
Material 3 application shell, accessible navigation, responsive light/dark
themes, and the initial Today and Medicines experiences.

## Requirements

- Flutter 3.41.9 or a compatible stable release
- Android SDK with API 35 and Build Tools 35
- JDK 21 (the system JDK 25 is not compatible with this Gradle toolchain)

## Run and verify

```bash
flutter --no-version-check pub get
flutter --no-version-check analyze
flutter --no-version-check test
JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 \
  flutter --no-version-check build apk --debug
```

Run on a connected Android device or emulator with:

```bash
JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 \
  flutter --no-version-check run
```

The Android application ID is `com.caremate.app` and the minimum supported
Android version is API 26 (Android 8.0).
