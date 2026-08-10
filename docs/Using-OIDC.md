# OIDC and PowerAuth Integration (Flutter)

- [Introduction](#introduction)
- [Getting an Instance](#getting-an-instance)
- [Retrieving Configuration](#retrieving-configuration)
- [Preparing OIDC Authorization Data](#preparing-oidc-authorization-data)
- [Registering URL Schemes for Deeplinks](#registering-url-schemes-for-deeplinks)
- [Open authorize URL in a web browser](#open-authorize-url-in-a-web-browser)
- [Handling URL Callbacks](#handling-url-callbacks)
- [Initiating PowerAuth Activation with OIDC](#initiating-powerauth-activation-with-oidc)
- [WMTOIDCUtils](#wmtoidcutils)

## Introduction

The OIDC and PowerAuth integration enables secure user authentication and the preparation of necessary attributes to initiate a PowerAuth activation. This integration provides tools for managing OpenID Connect (OIDC) flows, including preparing for OIDC activation, processing web callbacks, and handling PKCE codes and authorization URLs.

OIDC is commonly used for scenarios like secure user login, authorization to access resources, or linking third-party accounts.

<!-- begin box warning -->
**Note:** Before using the OIDC and PowerAuth integration, you need to have a `PowerAuthSDK` object available.
<!-- end -->

The integration communicates with the [OpenID Connect Standard](https://openid.net/connect/) and enhances the process with secure PKCE (Proof Key for Code Exchange) and state validation to ensure the integrity of the OIDC flow.

## Getting an Instance

The instance of the `WMTOIDC` can be accessed after creating the main object of the SDK:

```dart
final mtoken = await powerAuthInstance.createMobileToken();
final oidc = mtoken.oidc;
```

## Retrieving Configuration

The `getConfig` method retrieves the OIDC provider configuration based on a predefined `providerId`, returning a `WMTOIDCConfig` object with essential details about the provider, client, and PKCE settings.

```dart
final oidcConfig = await oidc.getConfig(providerId);
```

### WMTOIDCConfig

The `WMTOIDCConfig` structure contains essential OIDC configuration values for authentication.

| Property       | Type     | Description                                                                                     |
|----------------|----------|-------------------------------------------------------------------------------------------------|
| `providerId`   | `String` | The unique identifier for the OIDC provider.                                                    |
| `clientId`     | `String` | The OAuth 2.0 client ID used to form the URL for the authorization request.                     |
| `scopes`       | `String` | A space-delimited list of OAuth 2.0 scopes for the authorization request.                       |
| `authorizeUri` | `String` | The OAuth 2.0 authorization URI where the user is redirected for authentication.                |
| `redirectUri`  | `String` | The OAuth 2.0 redirect URI where the server sends responses after authentication.               |
| `pkceEnabled`  | `bool`   | Indicates whether PKCE (Proof Key for Code Exchange) should be used in the authentication flow. |

## Preparing OIDC Authorization Data

The `prepareAuthorizationData` method generates the necessary data for initiating the OIDC authorization process from `WMTOIDCConfig`. `WMTOIDCConfig` can be obtained by calling `getConfig(providerId)` or instantiated directly. 

### WMTOIDCAuthorizationRequest

Encapsulates the data required to initiate the OIDC authorization flow and also other properties for the PowerAuth activation flow.

| Property       | Type     | Description                                              |
|----------------|----------|----------------------------------------------------------|
| `authorizeUri` | `Uri`    | URI to redirect the user for OIDC authentication.       |
| `providerId`   | `String` | Identifier for the OIDC provider configuration.         |
| `nonce`        | `String` | Random value to prevent replay attacks.                 |
| `state`        | `String` | Random value to maintain state between request/callback.|
| `codeVerifier` | `String` | PKCE code verifier, if applicable.                      |

### Example

```dart
try {
  final authRequest = await oidc.prepareAuthorizationData(oidcConfig);

  // Use authRequest.authorizeUri to open the secure browser
} catch (error) {
  // Handle failure
}
```

## Registering URL Schemes for Deeplinks

Before the Flutter application can receive an OIDC callback, each platform must register the redirect URI scheme used by your OIDC provider. Registration is fully platform-specific.

### iOS (Info.plist)

iOS requires registering a custom URL scheme in `Info.plist` so the app can receive the callback from the OIDC authorization flow.

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>myapp</string>
    </array>
    <key>CFBundleURLName</key>
    <string>com.example.myapp</string>
  </dict>
</array>
```

On iOS, the full callback URI will be `myapp://oidc/callback` (scheme `myapp` + host `oidc` + path `/callback`).

### Android (AndroidManifest)

In your Android project (`android/app/src/main/AndroidManifest.xml`), register an `intent-filter` for your redirect URI, for example `myapp://oidc/callback`:

```xml
<activity
    android:name=".YourDeeplinkActivity"
    android:launchMode="singleTop">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="myapp"
            android:host="oidc"
            android:path="/callback" />
    </intent-filter>
</activity>
```

The scheme, host, and path must correspond to your redirect URI (for example, `myapp://oidc/callback`). The activity receiving the callback can forward the URL into your Flutter layer.

## Open authorize URL in a web browser

After preparing the OIDC authorization request, the application must open the authorization URL in a secure browser context. Unlike native iOS and Android, Flutter does not provide a unified API for secure authentication sessions. For this reason, **we do not recommend opening the authorization URL using generic Flutter utilities** such as basic URL launchers or embedded WebViews.

### Recommended Approach

To maintain the same security level as the native SDKs, the authorization URL should always be opened using the **native secure browser mechanisms** provided by each platform:

- **iOS:** `ASWebAuthenticationSession`  
- **Android:** Chrome Custom Tabs (or an equivalent secure browser tab)

These mechanisms:

- Provide a secure, isolated environment for authentication  
- Improve user experience through shared browser sessions  
- Ensure reliable redirect handling  
- Match security expectations for OIDC-based workflows

### Flutter Integration

Because Flutter does not expose these APIs directly, the application is expected to:

1. Prepare the authorization URL using `WMTOIDCUtils.createAuthorizationUri()`.  
2. Forward the URL to native platform code (for example, via a Flutter `MethodChannel`).  
3. Open the authorization URL using the platform’s secure browser mechanism.


## Handling URL Callbacks

Once both platforms are able to receive the redirect URI, you must hand the callback Uri over to the OIDC flow in your Flutter application. Flutter itself does not process native callbacks automatically; your native app code is responsible for forwarding the URL.

### iOS Callback Handling

Implement one of the following depending on your app lifecycle.

#### AppDelegate.swift

```swift
func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
) -> Bool {

    // Forward the OIDC callback URL to Flutter or your integration layer
    // For example: send the URL string over a MethodChannel
    return true
}
```

#### SceneDelegate.swift

```swift
func scene(_ scene: UIScene, openURLContexts contexts: Set<UIOpenURLContext>) {
    if let url = contexts.first?.url {
        // Forward the OIDC callback URL to Flutter or your integration layer
    }
}
```

### Android Callback Handling

When the intent filter triggers, the activity for receiving the deeplink callback defined in `AndroidManifest.xml` receives the OIDC callback URI via an intent:

```kotlin
override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)

    val uri = intent.data
    if (uri != null) {
        // Forward the OIDC callback URL to Flutter or your integration layer
        // For example: send the URL string over a MethodChannel
    }
}
```

On both platforms, the goal is to deliver the final callback URI into Flutter so that the Dart layer can process it.

## Initiating PowerAuth Activation with OIDC

The final step in the OIDC and PowerAuth integration is to use the `createOidcActivation` method. This extension function on `PowerAuthSDK` initiates the activation process by calling the PowerAuth Standard RESTful API.

```dart
final activationAttributes = WMTOIDCUtils.processWebCallback(
  uri: redirectUri,
  authData: oidcAuthData,
);

try {
  final activationResult = await powerAuthInstance.createOidcActivation(
    activationAttributes,
    activationName: "Petr's phone",
  );

  // No error occurred, proceed to credentials entry (PIN prompt, Enable Biometry, ...)
  // and persist the activation. The 'activationResult' contains an
  // 'activationFingerprint' property representing the device public key,
  // which may be used as a visual confirmation.
} on PowerAuthException catch (e) {
  // Handle PowerAuth-specific exception
} catch (e) {
  // Handle unknown exception
}
```

## WMTOIDCUtils

`WMTOIDCUtils` provides helper methods for generating PKCE codes, creating authorization URLs, and processing OIDC callback URLs into PowerAuth activation attributes. The implementation uses `PowerAuthCryptoUtils` for cryptographically secure randomness and SHA-256 hashing.

### PKCE

Provides methods for generating PKCE codes.

- **`createPKCE({ required int dataLength })`**  

Generates a `WMTPKCECodes` instance containing `codeVerifier`, `codeChallenge`, and `codeMethod` (`S256`). The `dataLength` parameter specifies the number of random bytes used for the code verifier (internally clamped to a safe range, typically 32–96 bytes, which corresponds to 43–128 Base64 URL-safe characters).

```dart
try {
  final pkceCodes = await WMTOIDCUtils.createPKCE(dataLength: 32);
  // PKCE codes created successfully
} on WMTException catch (e) {
  // Error generating PKCE codes
}
```

### Random String Generation

Provides a method to generate cryptographically secure random strings in Base64 URL-safe format, commonly used for nonces, states, or custom PKCE verifiers.

- **`getRandomBase64UrlSafe(int dataLength)`**  

Generates a random Base64 URL-safe string (without padding) using `PowerAuthCryptoUtils.randomBytes`.

```dart
try {
  final nonce = await WMTOIDCUtils.getRandomBase64UrlSafe(32);
  // Random string generated successfully
} on WMTException catch (e) {
  // Error generating random string
}
```

### Authorization URL

Provides a method for constructing the OIDC authorization URL with all required query parameters.

- **`createAuthorizationUri({ required WMTOIDCConfig config, required String nonce, required String state, WMTPKCECodes? pkceCodes })`**  

Creates a `Uri` for the OIDC authorization request using values from `WMTOIDCConfig` (authorize URI, client ID, redirect URI, scopes) and the supplied `nonce`, `state`, and optional PKCE codes.

```dart
try {
  final uri = WMTOIDCUtils.createAuthorizationUri(
    config: oidcConfig,
    nonce: nonce,
    state: state,
    pkceCodes: pkceCodes,
  );
  // Use `uri` with your chosen secure browser integration
} on WMTException catch (e) {
  // Authorization URL creation failed
}
```

### Web Callback Processing

Provides a method to process the OIDC callback URL and convert it into PowerAuth activation attributes.

- **`processWebCallback({ required Uri uri, required WMTOIDCAuthorizationRequest authData })`**  

Validates the callback `Uri`, extracts the authorization code and state, compares the state with `authData.state`, and returns `WMTOIDCPowerAuthActivationAttributes` that can be used to start a PowerAuth activation.

```dart
try {
  final activationAttributes = WMTOIDCUtils.processWebCallback(
    uri: callbackUri,
    authData: authRequest,
  );

  // Activation can continue using activationAttributes,
  // for example by passing them to your PowerAuth activation flow.
} on WMTException catch (e) {
  // Activation attributes cannot be created (invalid or mismatched callback)
}
```

## Read Next
  
- [Server Error Handling](./Server-Error-Handling.md)
