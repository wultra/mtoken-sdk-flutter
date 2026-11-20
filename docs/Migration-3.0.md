# Migration from 2.0.x to 3.0.x

This guide provides instructions for migrating from **Wultra Mobile Token SDK for Flutter** version `2.0.x` to version `3.0.x`.

## PowerAuth Mobile Flutter SDK 3.0

Version 3.0.x uses PowerAuth Mobile Flutter SDK `3.0.0`, which is built on the native PowerAuth Mobile SDK 2.1. The Flutter, Dart, and Android requirements are the same as in version 2.0.x.

- The minimum supported iOS version is now 15.0. Set the Runner target's minimum deployment version to iOS 15.0 or newer in Xcode. If your application uses CocoaPods, also set `platform :ios, '15.0'` in `ios/Podfile`.
- `PowerAuthPassword.addCharacter()`, `insertCharacter()`, `removeCharacterAt()`, and `removeLastCharacter()` are deprecated. Use `addCodePoints()`, `insertCodePoint()`, `removeCodePointAt()`, and `removeLastCodePoint()` instead.

See the [PowerAuth Mobile Flutter SDK changelog](https://github.com/wultra/flutter-powerauth-mobile-sdk/blob/develop/docs/Changelog.md) for all changes.

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

The configuration is immutable. To change the language or user agent at runtime, use `setAcceptLanguage` or the `acceptLanguage` and `userAgent` properties of the services.

## Request Interceptors

The `requestProcessor` argument was removed from all service calls and from operation polling, together with the `WMTRequestProcessor` type. Move your processor to `WMTConfiguration.requestInterceptors`. It then applies to every request of `operations`, `push`, `inbox`, and `oidc`:

```dart
// Before
await mtoken.operations.getOperations(requestProcessor: myProcessor);

// After
final mtoken = await powerAuth.createMobileToken(
  configuration: WMTConfiguration(requestInterceptors: [myProcessor]),
);
await mtoken.operations.getOperations();
```

Interceptors must be synchronous. See [Request Interceptors](Configuration.md#request-interceptors) for details.
