# Migration from 1.0.x to 2.0.x

This guide provides instructions for migrating from **Wultra Mobile Token SDK for Flutter** version `1.0.x` to version `2.0.x`.

## PowerAuth Mobile Flutter SDK 2.0

Version 2.0.x uses PowerAuth Mobile Flutter SDK `2.0.0-beta.1`. It requires Flutter 3.44, Dart 3.12, Android 6.0 (API 23), Android compile SDK 37, and Java 17. See the [PowerAuth 1.4 to 2.0 migration guide](https://github.com/wultra/flutter-powerauth-mobile-sdk/blob/develop-pqa/docs/Migration-from-1.4-to-2.0.md) for configuration, protocol algorithm, and activation upgrade requirements.

The example project uses the verified minimum API 37 toolchain: AGP 9.1.1, Gradle 9.3.1, JDK 17, and built-in Kotlin.

PowerAuth configuration is now asynchronous, so creating the Mobile Token instance must be awaited:

```dart
// Before
final mtoken = powerAuth.createMobileToken();

// After
final mtoken = await powerAuth.createMobileToken();
```

## Mobile Token Configuration

`WultraMobileToken.create()` and `PowerAuth.createMobileToken()` now take a single `WMTConfiguration` object. The `acceptLanguage` and `userAgent` arguments moved into it:

```dart
// Before
final mtoken = await powerAuth.createMobileToken(
  acceptLanguage: "fr",
  userAgent: WMTUserAgent.custom("MyCustomUserAgent"),
);

// After
final mtoken = await powerAuth.createMobileToken(
  configuration: WMTConfiguration(
    acceptLanguage: "fr",
    userAgent: WMTUserAgent.custom("MyCustomUserAgent"),
  ),
);
```

The configuration is immutable. Use `setAcceptLanguage` or the service `acceptLanguage` and `userAgent` properties to change these headers at runtime.

## Request Interceptors

The `requestProcessor` argument of all service calls and operation polling and the `WMTRequestProcessor` type were removed. Move your processor to `WMTConfiguration.requestInterceptors`. It then applies to every request of `operations`, `push`, `inbox`, and `oidc`:

```dart
// Before
await mtoken.operations.getOperations(requestProcessor: myProcessor);

// After
final mtoken = await powerAuth.createMobileToken(
  configuration: WMTConfiguration(requestInterceptors: [myProcessor]),
);
await mtoken.operations.getOperations();
```

Interceptors must be synchronous. See [Request Interceptors](Language-UserAgent-Configuration.md#request-interceptors).

## Pre-Approval Screen API

The singular `preApprovalScreen` property on `WMTUserOperationUIData` has been replaced by the plural `preApprovalScreens` list to support multi-screen pre-approval flows.

### Reading

```dart
// Before (1.0.x)
final screen = operation.ui?.preApprovalScreen;

// After (2.0.x)
final screens = operation.ui?.preApprovalScreens;
final firstScreen = screens?.first;
```

### Constructing

The `preApprovalScreen` constructor parameter has been removed. Use `preApprovalScreens` (a `List<WMTPreApprovalScreen>`) instead.

```dart
// Before (1.0.x)
final uiData = WMTUserOperationUIData(
  preApprovalScreen: myScreen,
  // ...
);

// After (2.0.x)
final uiData = WMTUserOperationUIData(
  preApprovalScreens: [myScreen],
  // ...
);
```
