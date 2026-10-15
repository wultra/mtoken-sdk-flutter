# Language and User-Agent Configuration

## Content Language

Before using any methods from this SDK that call the backend, a proper language should be set. 
A properly translated content is served based on this configuration. 

<!-- begin box warning -->
Note: Content language capabilities are limited by the implementation of the server - it must support the provided language.
<!-- end -->

### Usage

Set `WMTConfiguration.acceptLanguage` when using the asynchronous `WultraMobileToken.create` or `PowerAuth.createMobileToken` helper.

If you need to change the language at runtime, you can use the `setAcceptLanguage` method.

### Default Value and Format

The default value is `en`. With other languages, we use values compliant with standard RFC [Accept-Language](https://tools.ietf.org/html/rfc7231#section-5.3.5).

## User-Agent

In the same manner, a user agent can be set. 
The user agent is sent with every request to the server (as a standard `User-Agent` HTTP header) and can be used for device/system detection.

### Usage

Set `WMTConfiguration.userAgent` when using the asynchronous `WultraMobileToken.create` or `PowerAuth.createMobileToken` helper.

A configured request interceptor can override the User-Agent header before dispatch.

### Default User Agent

The default value will look like: `MobileTokenFlutter/1.0.0 my.company.example/2.5.1 (Android; Samsung Galaxy S21)`.

## Example

```dart
// create the WultraMobileToken instance set to french and with custom user agent
final mtoken = await powerAuth.createMobileToken(
  configuration: WMTConfiguration(
    acceptLanguage: "fr",
    userAgent: WMTUserAgent.custom("MyCustomUserAgent"),
  ),
);

// If needed, you can change the language at runtime
mtoken.setAcceptLanguage("de"); // set "requested content" to german language
```

## Request Interceptors

Configure `WMTConfiguration.requestInterceptors` to modify the finalized mutable `HttpHeaders` of every outgoing request. The same configuration applies to `operations`, `push`, `inbox`, and `oidc`, including operation polling.

A `WMTRequestInterceptor` is a synchronous `void Function(HttpHeaders headers)`. Do not use an `async` closure: if an interceptor returns a `Future`, the request is not sent and the call fails with `WMTException`. Interceptors run in declaration order after the SDK prepares its standard headers, PowerAuth authorization, and optional E2EE encryption headers. Each interceptor observes previous mutations and can override a header with `headers.set`. Outgoing-request logging includes the resulting headers.

For example, add an `X-Correlation-ID` header to trace requests across your backend services:

```dart
final mtoken = await powerAuth.createMobileToken(
  configuration: WMTConfiguration(
    requestInterceptors: [
      (headers) => headers.set("X-Correlation-ID", generateCorrelationId()),
    ],
  ),
);
await mtoken.operations.getOperations();
```

Here, `generateCorrelationId()` is your application's unique ID generator and is called for every request.

The configuration is immutable after construction. Its interceptor list is defensively copied and cannot be modified; changing the original list has no effect. Interceptors can read current application state when they run. Create another Mobile Token instance to configure a different list. The existing service language and user-agent setters still allow runtime header changes without modifying the initial configuration.

Move existing per-call header customization into `requestInterceptors` when migrating. Service calls and polling no longer accept a per-call callback. Keep PowerAuth authorization and encryption headers intact so the server can authenticate and decrypt requests.
