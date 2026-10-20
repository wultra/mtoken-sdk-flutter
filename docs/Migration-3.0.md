# Migration from 2.0.x to 3.0.x

This guide provides instructions for migrating from **Wultra Mobile Token SDK for Flutter** version `2.0.x` to version `3.0.x`.

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
