# Using Operations

<!-- begin remove -->
- [Introduction](#introduction)
- [Getting an Instance](#getting-an-instance)
- [Retrieve Pending Operations](#retrieve-pending-operations)
- [Approve an Operation](#approve-an-operation)
- [Reject an Operation](#reject-an-operation)
- [Operation detail](#operation-detail)
- [Claim the Operation](#claim-the-operation)
- [Off-line Authorization](#off-line-authorization)
- [WMTUserOperation](#wmtuseroperation)
- [Creating a Custom Operation](#creating-a-custom-operation)
- [Pre-Approval Screens](#pre-approval-screens)
- [Mobile Token Data](#mobile-token-data)
- [TOTP ProximityCheck](#totp-proximity-check)

## Introduction
<!-- end -->

`WMTOperations` is responsible for operation handling like fetching the operation list or approving operations.

An operation can be anything you need to be approved or rejected by the user. It can be for example money transfer, login request, access approval, ...

<!-- begin box warning -->
Note: Before using `WMTOperations`, you need to have a `PowerAuth` object available and initialized with a valid activation. Without a valid PowerAuth activation, all endpoints will return an error.
<!-- end -->

`WMTOperations` communicates with the [Mobile Token API](https://developers.wultra.com/components/enrollment-server/develop/documentation/Mobile-Token-API).

## Getting an Instance

The instance of the `WMTOperations` can be accessed after creating the main object of the SDK:

```dart
final mtoken = await powerAuthInstance.createMobileToken();
final operations = mtoken.operations;
```

## Retrieve Pending Operations

To fetch the list with pending operations, you can call:

```dart
final list = await mtoken.operations.getOperations();
```

After you retrieve the pending operations, you can render them in the UI, for example, as a list of items with a detail of the operation shown after a tap.

<!-- begin box warning -->
Note: The language of the UI data inside the operation depends on the configuration of the [accept language](./Language-UserAgent-Configuration.md).
<!-- end -->

## Approve an Operation

To approve an operation use `authorize`. You can simply use it with the following examples:

```dart
// Approve operation with a password
final password = await PowerAuthPassword.fromString("1234");
final auth = PowerAuthAuthentication.password(password);
await mtoken.operations.authorize(operation, auth);
```

To approve operations with biometrics, your PowerAuth instance [needs to be configured with biometric factor](https://github.com/wultra/flutter-powerauth-mobile-sdk/blob/develop/docs/Biometry-Setup.md).

```dart
// Approve operation with biometrics
final WMTUserOperation operation; // operation to approve (for example from getOperations call)

// UserOperation contains information on biometrics that can be used
if (!operation.allowedSignatureType.variants.contains(WMTSignatureVariant.possessionBiometry)) {
  // Biometrics usage is not allowed on this operation
  return;
}

final auth = PowerAuthAuthentication.biometry(biometricPrompt: PowerAuthBiometricPrompt(
  promptTitle: "Authenticate",
  promptMessage: "Please authenticate with biometry",
));
await mtoken.operations.authorize(operation, auth);
```

### Passing Additional Mobile Token Data

With PowerAuth server 1.10+, you can pass additional customer-specific data during operation authorization using the `mobileTokenData` property. This can be useful for fraud detection systems (FDS) or other custom business logic.

```dart
// Approve operation with additional mobile token data
final fdsData = {
  "deviceFingerprint": "abc123def456",
  "riskScore": 0.8,
  "location": {
    "latitude": 50.0755,
    "longitude": 14.4378
  }
};

operation.mobileTokenData = fdsData;

final auth = PowerAuthAuthentication.password(password);
await mtoken.operations.authorize(operation, auth);
// continue with the flow ....
```

The `mobileTokenData` is completely optional, and the structure is customer-specific. If you don't need this functionality, you can continue using operations without providing this property.

## Reject an Operation

To reject an operation use `reject` (by operation ID) or `rejectOperation` (with the full operation). Operation rejection is confirmed by the possession factor, so there is no need to create the `PowerAuthAuthentication` object.

```dart
// Reject by operation ID
await mtoken.operations.reject(operation.id, WMTRejectionReason.incorrectData());

// Reject with the full operation object (which might also include mobileTokenData)
await mtoken.operations.rejectOperation(operation, WMTRejectionReason.incorrectData());
```

## Operation Detail

To get a detail of the operation based on operation ID use `detail`. Operation detail is confirmed by the possession factor, so there is no need for creating a `PowerAuthAuthentication` object. The returned result is the operation and its current status.

```dart
// Retrieve operation details based on the operation ID.
final operation = await mtoken.operations.getDetail(operationId);
```

## Claim the Operation

To claim a non-personalized operation use `claim`. 

A non-personalized operation refers to an operation that is initiated without a specific userId. In this state, the operation is not tied to a particular user. 

Operation claim is confirmed by the possession factor, so there is no need for creating a `PowerAuthAuthentication` object. The returned result is the operation and its current status. You can simply use it with the following example.

```dart
// Assigns the 'non-personalized' operation to the user
final operation = await mtoken.operations.claim(operationId);
```

## Operation History

You can retrieve an operation history via the `history` method. The returned result is operations and their current status.

```dart
final auth = PowerAuthAuthentication.password(password);
final response = await mtoken.operations.getHistory(auth);
```

## Off-line Authorization

In case the user is not online, you can use off-line authorizations. In this operation mode, the user needs to scan a QR code, enter a PIN code, or use biometrics, and rewrite the resulting code. Wultra provides a special format for [the operation QR codes](https://github.com/wultra/enrollment-server/blob/develop/docs/Offline-Signatures-QR-Code.md), which are automatically processed with the SDK.

### Processing Scanned QR Operation

```dart
final qrOperation = WMTQROperationParser.parse(scannedCode); // this method can throw a WMTException if the QR code is invalid
// verify the signature against the powerauth instance
final signingKey = switch (qrOperation.signature.signingKey) {
    WMTSigningKey.master => PowerAuthSignatureKeyId.masterEc,
    WMTSigningKey.personalized => PowerAuthSignatureKeyId.serverEc,
    WMTSigningKey.personalizedMac => PowerAuthSignatureKeyId.macPersonalized,
};
await powerAuth.verifyDigitalSignature(
    qrOperation.signature.signature,
    Uint8List.fromList(utf8.encode(qrOperation.signedData)),
    signingKey,
); // throws PowerAuthException with wrongSignature when the signature is invalid
```

### Authorizing Scanned QR Operation

<!-- begin box info -->
An offline operation needs to be __always__ approved with __a 2-factor scheme__ (password or biometrics).
<!-- end -->

<!-- begin box info -->
Each offline operation created on the server has an __URI ID__ to define its purpose and configuration. The default value used here is `/operation/authorize/offline` and can be modified with the `uriId` parameter in the `authorizeOffline` method.
<!-- end -->

#### With Password

```dart
final auth = PowerAuthAuthentication.password(password);
final offlineSignature = await mtoken.operations.authorizeOffline(qrOperation, auth);
// Display the signature to the user so it can be manually rewritten.
// Note that the operation will be signed even with the wrong password!
```

<!-- begin box info -->
An offline operation can and will be signed even with an incorrect password. The signature cannot be used for manual approval in such a case. This behavior cannot be detected, so you should warn the user that an incorrect password will result in an incorrect "approval code".
<!-- end -->

#### With Password and Custom `uriId`

```dart
final auth = PowerAuthAuthentication.password(password);
final offlineSignature = await mtoken.operations.authorizeOffline(qrOperation, auth, uriId: "/confirm/offline/operation");
// Display the signature to the user so it can be manually rewritten.
// Note that the operation will be signed even with the wrong password!
```

#### With Biometrics

To approve offline operations with biometrics, your PowerAuth instance [needs to be configured with biometric factor](https://github.com/wultra/flutter-powerauth-mobile-sdk/blob/develop/docs/Biometry-Setup.md).

To determine if biometrics can be used for offline operation authorization, use `WMTQROperation.flags.biometricsAllowed`.

```dart
// Approves QR operation with biometrics

if (!qrOperation.flags.biometricsAllowed) {
  // biometrics usage is not allowed on this operation
  return
}

final auth = PowerAuthAuthentication.biometry(biometricPrompt: PowerAuthBiometricPrompt(
  promptTitle: "Authenticate",
  promptMessage: "Please authenticate with biometry",
));

final offlineSignature = await mtoken.operations.authorizeOffline(qrOperation, auth);
// Display the signature to the user so it can be manually rewritten.
```

## WMTUserOperation

Operation objects retrieved through the `getOperations`, `getDetail` or `claim` methods are called "user operations".

Under this abstract name, you can imagine for example "Login operation", which is a request for signing in to the online account in a web browser on another device. **In general, it can be any operation that can be either approved or rejected by the user.**

Besides the basic operation data like `id` or `data` string to sign, the `WMTUserOperation` contains additional information like:
- `name`: Type of the operation, e.g. `LOGIN`, `TRANSFER`, `PAYMENT`.
- `status`: Current status of the operation, e.g. `PENDING`, `APPROVED`, `REJECTED`.
- `formData`: Additional data that can be used to render the operation in the UI, e.g. `{"amount": "1000", "currency": "EUR"}`.
- `ui`: UI configuration for the operation
- etc...

Visually, the operation should be displayed as an info page with all the attributes (rows) of such an operation, where the user can decide if he wants to approve or reject it.

## Creating a Custom Operation

In some specific scenarios, you might need to approve or reject an operation that you received through a different channel than `getOperations`. In such cases, you can implement the `WMTOnlineOperation` interface in your custom class and then feed created objects to both `authorize` and `rejectOperation` methods.

Definition of the `WMTOnlineOperation`:

```dart
abstract class WMTOnlineOperation {
  
  /// Unique operation identifier. 
  String get id;

  /// Actual data that will be signed.
  /// 
  /// This shouldn't be visible to the user.
  String get data;

  /// Additional information with proximity check data 
  abstract WMTOperationProximityCheck? proximityCheck;

  /// Additional mobile token data for authorization (available with PowerAuth server 1.10+) 
  abstract Object? mobileTokenData;
}
```

## Pre-Approval Screens

Pre-approval screens define additional UI that can be displayed before the user decides to approve or reject an operation. They allow displaying structured instructions, warnings, or interactive elements to the user.

The screens are available via `WMTUserOperation.ui.preApprovalScreens` and may contain multiple screens that the user navigates through.

Types:

- `WARNING`
- `INFO`
- `QR_SCAN` – this type indicates that the `WMTOperationProximityCheck` must be used
- `UNKNOWN` – fallback value assigned by the SDK when the server sends an unrecognized screen type

A pre-approval screen can contain the following building blocks:

- Heading and message – textual content displayed at the top of the screen.
- Optional metadata:
  - `id` – unique screen identifier
  - `backButton` – show a navigation back button
  - `image` – in-app asset identifier
- Elements – structured items that form the main content of the screen:
  - List item (`LIST_ITEM`) – text with optional `icon` and `style` (`INFO`, `WARNING`, `DANGER`).
  - Alert (`ALERT`) – highlighted box with `style` (`INFO`, `WARNING`, `DANGER`).
  - Button (`BUTTON`) – action element with `action` (`LINK`, `MAIL`, `PHONE`), plus optional `actionSettings` string describing additional behavior (e.g. `"REJECT"`).
- Controls – configuration of approve/decline actions:
  - Decline – `BACK` or `REJECT`, with optional `text`.
  - Approve – `SLIDER` or `BUTTON`, with optional `text` and optional countdown (`counter`). The counter defines how long (in seconds) the approve control remains disabled after the screen appears.
  - Layout options – `axis` (`HORIZONTAL` or `VERTICAL`) and `flip` (swap order of controls).

### Legacy Format Compatibility

The SDK supports the legacy singular `preApprovalScreen` payload from older server versions and automatically converts it to the new `preApprovalScreens` list. During this conversion, the following sentinel values are injected because the legacy format does not carry these fields:

- **`image`**: Set to `"fallback_image"`. Your UI layer should check for this value and render an appropriate default (e.g. a generic icon or no image).
- **`icon`** (on list item elements): Set to `"fallback_icon"`. Your UI layer should detect this value and provide a suitable default rendering.

These sentinels are only injected during legacy conversion — new-format payloads are passed through as-is. This behavior matches the iOS and Android SDKs.

## Mobile Token Data

With PowerAuth Server **1.10+**, you can pass additional, customer-specific metadata during operation authorization using the `mobileTokenData` property.
Since PowerAuth Server **2.0+**, you can also pass `mobileTokenData` when rejecting an operation.

This feature is especially useful for **fraud detection systems (FDS)**, customer risk evaluation, or other backend-specific business logic.

### Direct Map Approach

If you already have a static set of key–value pairs, you can directly assign a map to your operation:

```dart
operation.mobileTokenData = {
  'deviceFingerprint': 'abc123def456',
  'riskScore': 0.8,
  'location': {'latitude': 50.0755, 'longitude': 14.4378},
};
```

### Builder-Based Approach

For more dynamic, structured, or multi-step data, use the `WMTMobileTokenDataBuilder`.

```dart
// Create the builder (optionally with initial data)
final builder = WMTMobileTokenDataBuilder({'deviceFingerprint': 'abc123'});

// Add generic entries
builder.put('riskScore', 0.82);

// Assign to the operation
operation.mobileTokenData = builder.build();
```

### Record Helpers

Sometimes, additional data attached to `mobileTokenData` is not just a few key–value pairs. It can represent structured sections of information (for example, a timeline of user actions).

To support these cases, the SDK defines the `WMTMobileTokenDataRecord` interface:

```dart
abstract class WMTMobileTokenDataRecord {
  /// Top-level key under which this record is stored.
  String get key;

  /// Produces the value to store for this key.
  FutureOr<dynamic> build();
}
```

You can pass records to the builder with `await builder.putRecord(record)`.

### Predefined Record Helper: `WMTPreApprovalScreensRecorder`

The SDK includes a predefined implementation, `WMTPreApprovalScreensRecorder`, which records how users navigate through Pre-Approval screens.

Each recorded "visit" contains:

- Screen identifier (`screen`)
- Opening timestamp
- Closing timestamp
- User action (`CONTINUE`, `CLOSE`, `REJECT`, `SCAN`, etc.)

The `WMTPreApprovalScreensRecorder` exposes the following methods:

- `begin(id)` – starts a new visit for the given screen ID. If another visit is already open, it is automatically added to the list (without a closing timestamp or action).
- `end(id, action)` – closes the current visit if the given id matches. If no visit is open, but the most recent recorded visit has the same id and is still unclosed, it is finalized instead.
- `reset()` – resets recorded visits.

Timestamps are captured in local device time and shifted by the PowerAuth server time adjustment when the record is built (when you call `putRecord`). This ensures the payload contains server-synchronized timestamps even when the device clock is off or the time was not yet synchronized while the user navigated the screens. For best accuracy, pass the recorder to the builder at authorization time, not earlier.

```dart
// Create MobileTokenData builder instance
final builder = WMTMobileTokenDataBuilder();

// Create the screen recorder (requires a PowerAuth instance)
final screenRecorder = WMTPreApprovalScreensRecorder(powerAuth: powerAuth);

// Display UI for the PreApproval screen and record that it was shown
screenRecorder.begin(screen.id);
// Record when user leaves the PreApproval screen
screenRecorder.end(screen.id, WMTPreApprovalScreenAction.continueAction);

// ... repeat for all screens from operation.ui.preApprovalScreens

// When the PreApproval flow is finished, pass the recorder to the builder
await builder.putRecord(screenRecorder);

// Assign created mobileTokenData to the Operation before approving/rejecting
operation.mobileTokenData = builder.build();
```

The `mobileTokenData` is completely optional and the structure is customer-specific. If you don't need this functionality, you can continue using operations without providing this property.

## TOTP Proximity Check

Two-Factor Authentication (2FA) using Time-Based One-Time Passwords (TOTP) in the Operations is facilitated through the use of proximity check. This allows secure approval of operations through QR code scanning or deeplink handling.

**QR Code Flow:**

When the `WMTUserOperation.ui.preApprovalScreens` contains a screen with `type` == `QR_SCAN`, the app should open the camera to scan the QR code before confirming the operation. Use the camera to scan the QR code containing the necessary data payload for the operation.

**Deeplink Flow:**

When the app is launched via a deeplink, preserve the data from the deeplink and extract the relevant data. When operations are loaded compare the operation ID from the deeplink data to the operations within the app to find a match.

- Assign TOTP and Type to the Operation.
- Once the QR code is scanned or a match from the deeplink is found, create a `WMTOperationProximityCheck` with:
  - `totp`: The actual Time-Based One-Time Password.
  - `type`: Set to `WMTProximityCheckType.qrCode` or `WMTProximityCheckType.deeplink`.

- Automatic Time Synchronization
  The SDK automatically produces server-aligned timestamps (`timestampReceived` and `timestampSent`) in the authorization request during `authorize`. This ensures correct timestamps even when the device system clock has been manually changed. If time is not yet synchronized with the server, the SDK will synchronize it before sending the authorization request.

```dart
// Create the proximity check — just provide the TOTP and type.
// The SDK handles timestamp adjustment automatically during authorization.
operation.proximityCheck = WMTOperationProximityCheck(totp: "123456", type: WMTProximityCheckType.qrCode);
await mtoken.operations.authorize(operation, authentication);
```


### WMTPACUtils

For convenience, a utility class for parsing and extracting data from QR codes and deeplinks used in the PAC (Proximity Anti-fraud Check), is provided.

- two methods are provided:
  - `WMTPACData parseDeeplink(String url)` - url is expected to be in the format `scheme://code=$JWT` or `scheme://operation?oid=5b753d0d-d59a-49b7-bec4-eae258566dbb&potp=12345678`
  - `WMTPACData parseQRCode(String code)` - code is to be expected in the same format as deeplink formats or as a plain JWT
  - mentioned JWT should be in the format `{"type":"JWT", "alg":"none"}.{"oid":"5b753d0d-d59a-49b7-bec4-eae258566dbb", "potp":"12345678"}`

- Accepted formats:
  - notice that the totp key in JWT and in query shall be `potp`!

## Read Next

- [Using Push](./Using-Push.md)
