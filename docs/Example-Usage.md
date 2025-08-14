# Example Usage

This is an example of the most common use case of this SDK - fetching operations and approving them.

## SDK Integration

Follow the [SDK Integration](./SDK-Integration.md) tutorial for SDK installation.

## Example Code

Example Dart usage:

```dart

// PowerAuth instance needs to be configured and a user-activated instance.
// More about PowerAuth SDK can be found here: https://github.com/wultra/flutter-powerauth-mobile-sdk

Future<void> exampleAuthorizeOperation(PowerAuth powerAuth) async {

  // Make sure that PowerAuth is initialized and activated

  final mtoken = powerAuth.createMobileToken(); // create the WultraMobileToken instance

  try {
    final operations = await mtoken.operations.getOperations(); // get operation list

    if (operations.length > 0) { // make sure that we retrieved some operations

      // Here you should present the operation to the user, e.g. in a dialog, for example purposes
      // we print just the operationID.
      // In this example, we simulate that the user entered a PIN "1234".
      // In a real application, you should use a secure way to get the user's PIN or password.

      final operation = operations[0]; // get the first operation from the list
      print("Operation ID: ${operation.id}"); // print operation ID
      final password = await PowerAuthPassword.fromString("1234"); // simulate that user entered PIN 1234
      final auth = PowerAuthAuthentication.password(password); // create authentication object
      await mtoken.operations.authorize(operation, auth); // authorize the operation

      print("Operation authorized successfully!"); // operation was successfully authorized

      // operation authorized
    }
  } catch (e) {
    // something failed
    print("Failure: ${e.toString()}");
  }
}
```

## Read Next

- [Using Operations](./Using-Operations.md)