# Debug and release APK builds

Issue #23

## Build commands

Both builds need `keys.json` (copied from `keys.example.json`) so the USDA API
key is compiled into the app:

```bash
flutter build apk --debug --dart-define-from-file=keys.json
flutter build apk --release --dart-define-from-file=keys.json
```

Without `--dart-define-from-file=keys.json` the app still builds, but every
USDA request fails with "Missing USDA API key".

## Output location

| Build   | Path                                              |
|---------|---------------------------------------------------|
| Debug   | `build/app/outputs/flutter-apk/app-debug.apk`     |
| Release | `build/app/outputs/flutter-apk/app-release.apk`   |

The `build/` folder is ignored by git, so the APKs are never committed. The
release APK submitted on Canvas is a copy of `app-release.apk`.

## Measured sizes

Built on Oct 28, 2026 with Flutter 3.44.4 (Dart 3.12.2) on Windows 11.

| Build   | Size (bytes) | Size     | First build time |
|---------|-------------:|---------:|-----------------:|
| Debug   | 168,774,989  | 161.0 MB | 90 s             |
| Release | 54,893,745   | 52.4 MB  | 306 s            |

The release APK is about 3 times smaller than the debug APK. Both are "fat"
APKs that hold native code for three CPU types (arm64-v8a, armeabi-v7a, and
x86_64), so one file installs on phones and on the emulator.

The release APK was installed on an Android 17 (API 37) emulator, and a USDA
search for "chicken" returned 20 results.

## Differences between debug and release

### Size

- **Debug** ships the Dart code as `kernel_blob.bin` (49 MB uncompressed) so
  it can be run by the Dart VM and changed with hot reload. It also uses the
  debug Flutter engine (`libflutter.so`, about 38 MB per CPU type) and a
  Vulkan validation layer used for graphics debugging.
- **Release** compiles the Dart code ahead of time into machine code
  (`libapp.so`, about 6 MB per CPU type) and uses the smaller release engine
  (about 12 MB per CPU type). Unused icons are also removed: the Material
  Icons font shrank from 1,645,184 bytes to 3,620 bytes (99.8% smaller).

### Performance

- **Debug** runs Dart with a JIT (just-in-time) compiler and keeps `assert`
  checks on. Animations and scrolling can stutter, and app start is slower.
  This is normal and is not how the real app performs.
- **Release** runs AOT (ahead-of-time) compiled code with asserts removed, so
  it starts faster and scrolls smoothly.

### Debug banner and tools

- **Debug** shows the red "DEBUG" banner in the top-right corner and supports
  hot reload, hot restart, Flutter DevTools, and `debugPrint` output in the
  console.
- **Release** has no banner and no DevTools or hot reload. Platito's own
  code has no `print` or `debugPrint` calls, so it logs nothing in either
  build.

### Signing

- **Debug** is signed with the Android debug key that the SDK creates
  automatically on this computer.
- **Release** is also signed with the debug key for now. In
  `android/app/build.gradle.kts` the release build type uses
  `signingConfig = signingConfigs.getByName("debug")`. This is enough to
  install the APK on a phone or emulator for grading. Publishing on Google
  Play would need a private upload key and a release signing config instead.

## Note about the API key

`--dart-define-from-file` compiles the USDA key into the APK, so anyone who
unpacks the APK could find it. The key is kept out of git (`keys.json` is
ignored), which is the main goal for this project. A production app would
send requests through its own server so the key never ships to phones.
