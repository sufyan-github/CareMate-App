# CareMate mobile

Android-first Flutter client for CareMate. The current foundation provides the
Material 3 application shell, accessible navigation, responsive light/dark
themes, Today and Medicines experiences, encrypted offline plan storage, and a
durable Sync Mutation outbox backed by Android WorkManager.

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

## Physical offline verification

Build with the host API address, install, and create the reverse tunnel:

```bash
flutter build apk --debug \
  --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1
adb reverse tcp:3000 tcp:3000
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

After opening Today online once, remove the tunnel and cold-start the app:

```bash
adb reverse --remove tcp:3000
adb shell am force-stop com.caremate.app
adb shell am start -n com.caremate.app/.MainActivity
```

The saved-plan banner and pending-sync experience must remain available. Restore
the tunnel with `adb reverse tcp:3000 tcp:3000`, choose **Sync now**, and verify
that authoritative server state clears the pending marker. The development APK
packages `libsqlite3mc.so`; runtime startup refuses an unencrypted SQLite build.
