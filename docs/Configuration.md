# Mobile Token Configuration

The Mobile Token instance is configured with a `WMTConfiguration` object passed to `WultraMobileToken.create` or `PowerAuth.createMobileToken`. The configuration is shared by all services (`operations`, `push`, `inbox`, and `oidc`) and is immutable after construction.

| Property              | Default                  | Description                                                   |
|-----------------------|--------------------------|---------------------------------------------------------------|
| `acceptLanguage`      | `en`                     | Initial language of the [content](#content-language).          |
| `userAgent`           | SDK default user agent   | Initial [User-Agent](#user-agent) header.                     |
| `requestInterceptors` | empty                    | [Request interceptors](#request-interceptors) applied to every request. |

```dart
final mtoken = await powerAuth.createMobileToken(
  configuration: WMTConfiguration(
    acceptLanguage: "fr",
    userAgent: WMTUserAgent.custom("MyCustomUserAgent"),
    requestInterceptors: [
      (headers) => headers.set("X-Correlation-ID", generateCorrelationId()),
    ],
  ),
);
```

## Content Language

Before using any methods from this SDK that call the backend, a proper language should be set. 
A properly translated content is served based on this configuration. 

<!-- begin box warning -->
Note: Content language capabilities are limited by the implementation of the server - it must support the provided language.
<!-- end -->

### Usage

Set the initial language with `WMTConfiguration.acceptLanguage`. To change the language at runtime, use the `setAcceptLanguage` method:

```dart
mtoken.setAcceptLanguage("de"); // set "requested content" to german language
```

### Default Value and Format

The default value is `en`. With other languages, we use values compliant with standard RFC [Accept-Language](https://tools.ietf.org/html/rfc7231#section-5.3.5).

## User-Agent

In the same manner, a user agent can be set. 
The user agent is sent with every request to the server (as a standard `User-Agent` HTTP header) and can be used for device/system detection.

### Usage

Set the initial user agent with `WMTConfiguration.userAgent`. To change it at runtime, set the `userAgent` property of a service, for example `mtoken.operations.userAgent`.

### Default User Agent

The default value will look like: `MobileTokenFlutter/1.0.0 my.company.example/2.5.1 (Android; Samsung Galaxy S21)`.

## Request Interceptors

Request interceptors let you modify the HTTP headers of every outgoing request, including operation polling. Configure them with `WMTConfiguration.requestInterceptors`.

For example, add an `X-Correlation-ID` header to trace requests across your backend services:

```dart
final mtoken = await powerAuth.createMobileToken(
  configuration: WMTConfiguration(
    requestInterceptors: [
      (headers) => headers.set("X-Correlation-ID", generateCorrelationId()),
    ],
  ),
);
```

Here, `generateCorrelationId()` is your application's unique ID generator and is called for every request.

### Behavior

- A `WMTRequestInterceptor` is a synchronous `void Function(HttpHeaders headers)`.
- Interceptors run in the declared order, right before the request is sent. At that point, the SDK has already set the standard headers, PowerAuth authorization, and E2EE encryption headers.
- Each interceptor sees the changes made by the previous ones and can override any header with `headers.set`.
- Request logging shows the headers after all interceptors ran.
- The interceptor list is copied when the configuration is created. Later changes to the original list have no effect. To use a different list, create another Mobile Token instance.

<!-- begin box warning -->
Interceptors must be synchronous. If an interceptor returns a `Future` (for example, an `async` closure), the request is not sent and the call fails with `WMTException`.
<!-- end -->

<!-- begin box warning -->
Do not modify or remove the PowerAuth authorization and encryption headers. Without them, the server cannot authenticate or decrypt the request.
<!-- end -->
