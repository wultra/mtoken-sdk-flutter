# Server Error Handling

When the request fails on the server, it can return a known error for you to interpret to the user and use to log it
for better error reporting.

Such errors are represented by the `WMTResponseError` class, which contains the `code` and `message` properties and can be
found inside the `responseError` property of the `WMTException` class.

## Example error handling

```dart
// Approve operation with a password
Future<void> approve(WMTOnlineOperation operation, PowerAuthPassword password) async {
  try {
    final auth = PowerAuthAuthentication.password(password);
    await mtoken.operations.authorize(operation, auth);
  } on WMTException catch (e) {
    // process server error, if available
    print("Error: ${e.responseError?.message} (code: ${e.responseError?.code})");
  } catch (e) {
    // unexpected failure
  }
}
```

## Known API Error codes

If the `WMTException` has a `responseError`, the `code` property can contain the following errors:

| Value                       | Server value                   | Description                                                               |
|-----------------------------|--------------------------------|---------------------------------------------------------------------------|
| `genericError`              | `ERROR_GENERIC`                | When unexpected error happened.                                           |
| `authenticationFailure`     | `POWERAUTH_AUTH_FAIL`          | General authentication failure (wrong password, wrong activation state, etc...) |
| `invalidRequest`            | `INVALID_REQUEST`              | Invalid request sent – missing request object in request                  |
| `invalidActivation`         | `INVALID_ACTIVATION`           | Activation is not valid (it is different from configured activation)      |
| `invalidApplication`        | `INVALID_APPLICATION`          | Invalid application identifier is attempted for operation manipulation    |
| `invalidOperation`          | `INVALID_OPERATION`            | Invalid operation identifier is attempted for operation manipulation      |
| `activationError`           | `ERR_ACTIVATION`               | Error during activation                                                   |
| `authenticationError`       | `ERR_AUTHENTICATION`           | Error in case that PowerAuth authentication fails                         |
| `secureVaultError`          | `ERR_SECURE_VAULT`             | Error during secure vault unlocking                                       |
| `encryptionError`           | `ERR_ENCRYPTION`               | Returned in case encryption or decryption fails                           |
| `pushRegistrationFailed`    | `PUSH_REGISTRATION_FAILED`     | Failed to register push notifications                                     |
| `operationAlreadyFinished`  | `OPERATION_ALREADY_FINISHED`   | Operation is already finished                                             |
| `operationAlreadyFailed`    | `OPERATION_ALREADY_FAILED`     | Operation is already failed                                               |
| `operationAlreadyCancelled` | `OPERATION_ALREADY_CANCELED`   | Operation is cancelled                                                    |
| `operationExpired`          | `OPERATION_EXPIRED`            | Operation is expired                                                      |
| `operationFailed`           | `OPERATION_FAILED`             | Operation authorization failed                                            |

## Read Next
  
- [Language and User-Agent Configuration](./Language-UserAgent-Configuration.md)