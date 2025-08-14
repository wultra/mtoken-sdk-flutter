# Using Push

<!-- begin remove -->
- [Introduction](#introduction)
- [Getting an Instance](#getting-an-instance)
- [Registering to Push Notifications Example](#registering-to-push-notifications-example)

## Introduction
<!-- end -->

`WMTPush` is responsible for registering the device for the push notifications about the operations that are tied to the current `PowerAuth` activation. For example, a push notification is received when a new operation is created.

<!-- begin box warning -->
Note: Before using `WMTPush`, you need to have a `PowerAuth` object available and initialized with a valid activation. Without a valid `PowerAuth` activation, the service will return an error.
<!-- end -->

<!-- begin box warning -->
Note: `WMTPush` only registers the device to receive push notifications, it does not process them - you need to handle that by yourself.
<!-- end -->

`WMTPush` communicates with the [Mobile Token API](https://developers.wultra.com/components/enrollment-server/develop/documentation/Mobile-Token-API).

## Getting an Instance

The instance of the `WMTPush` can be accessed after creating the main object of the SDK:

```dart
final mtoken = powerAuthInstance.createMobileToken();
final push = mtoken.push;
```

## Registering to Push Notifications Example

```dart
String token; // Push token from the platform (e.g. Firebase Cloud Messaging or Apple Push Notification service)

// for the sake of the example, we assume the token is for FCM
final data = WMTPushPlatform.fcm(token);
await mtoken.push.register(data);
```

<!-- begin box warning -->
If you're using an older PowerAuth server version 1.9, you need to setup the platform object to support legacy push registration with:
```dart
final data = WMTPushPlatform.fcm(token).supportLegacyServer();
```
<!-- end -->

## Read Next
  
- [Using Inbox](./Using-Inbox.md)