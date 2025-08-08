# SDK Integration

## PowerAuth Flutter SDK Dependency

The PowerAuth Flutter SDK is a required dependency that will be automatically installed (if not already specified in your project).

### Compatible PowerAuth Mobile Flutter SDK Versions

| WMT Version | PowerAuth Flutter SDK |
|-------------|--------------------|
| `1.0.x`     | `^1.1.0`.          |

## Supported Platforms

The library is available for the following __Flutter 3.3.0+__ platforms:

- __Android 5.0 (API 21)__ and newer
- __iOS 13.4__ and newer

    ### How To Install

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
minSdkVersion 21
```

Also, make sure to enable Java 11:

```gradle
compileOptions {
    sourceCompatibility JavaVersion.VERSION_11
    targetCompatibility JavaVersion.VERSION_11
}
```

#### iOS

In `ios/Podfile`, ensure the platform version is at least 13.4:

```ruby
platform :ios, '13.4'
```

Then install pods:

```bash
cd ios
pod install
cd ..
```

#### 3. Import in your dart files

```dart
import 'package:mtoken_sdk_flutter/mtoken_sdk_flutter.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

void createMtokenInstance() {
  final powerAuth = PowerAuth("my-instance");
  // note that an activated PowerAuth instance is required. How to activate the PowerAuth instance, follow https://github.com/wultra/flutter-powerauth-mobile-sdk documentation.

  // Then, use PowerAuth's helper function to create the mtoken instance:
  final mtoken = powerAuth.createMobileToken();
}
```

## Read Next

- [Example Usage](./Example-Usage.md)
