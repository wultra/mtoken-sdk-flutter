# SDK Integration

## PowerAuth Flutter SDK Dependency

The PowerAuth Flutter SDK is a required dependency that will be automatically installed (if not already specified in your project).

### Compatible PowerAuth Mobile Flutter SDK Versions

| WMT Version | PowerAuth Flutter SDK |
|-------------|--------------------|
| `2.0.x`     | `2.0.0-beta.1`       |
| `1.0.x`     | `^1.1.0`           |

## Supported Platforms

The library is available for the following __Flutter 3.44.0+__ platforms:

- __Android 6.0 (API 23)__ and newer
- __iOS 13.4__ and newer

## How To Install

### 1. Prerequisites

- Flutter SDK installed ([Get Started](https://flutter.dev/docs/get-started/install))
- A working Flutter project (`flutter create my_app` if starting fresh)

### 2. Add Dependency

Open `pubspec.yaml` and add:

```yaml
dependencies:
  mtoken_sdk_flutter: ^1.0.0  # Check pub.dev for latest version
```

Then run:

```bash
flutter pub get
```

### 3. Configure Native Platforms

#### Android

In `android/app/build.gradle`, make sure to set the minimum SDK version:

```gradle
compileSdkVersion 37
minSdkVersion 23
```

Also, make sure to enable Java 17:

```gradle
compileOptions {
    sourceCompatibility JavaVersion.VERSION_17
    targetCompatibility JavaVersion.VERSION_17
}
```

#### iOS

The SDK supports both Swift Package Manager and CocoaPods. Swift Package Manager is recommended for new projects. Ensure its support is enabled in Flutter:

```bash
flutter config --enable-swift-package-manager
```

Set the Runner target's minimum deployment version to iOS 13.4 or newer in Xcode, then let Flutter resolve the packages:

```bash
flutter pub get
```

No CocoaPods installation or `Podfile` is required when Swift Package Manager is enabled.

Existing CocoaPods-based applications remain supported. When Swift Package Manager is disabled, Flutter uses the PowerAuth plugin's podspec and resolves its native `PowerAuth2` dependency through CocoaPods.

#### 4. Import in your Dart files

```dart
import 'package:mtoken_sdk_flutter/mtoken_sdk_flutter.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

Future<void> createMtokenInstance() async {
  final powerAuth = PowerAuth("my-instance");
  // note that an activated PowerAuth instance is required. How to activate the PowerAuth instance, follow https://github.com/wultra/flutter-powerauth-mobile-sdk documentation.

  // Then, use PowerAuth's helper function to create the mtoken instance:
  final mtoken = await powerAuth.createMobileToken();
}
```

## Read Next

- [Example Usage](./Example-Usage.md)
