# Using Inbox

<!-- begin remove -->
- [Introduction](#introduction)
- [Getting an Instance](#getting-an-instance)
- [Inbox Usage](#inbox-usage)
  - [Get Number of Unread Messages](#get-number-of-unread-messages)
  - [Get List of Messages](#get-list-of-messages)
  - [Get Message Detail](#get-message-detail)
  - [Set Message as Read](#set-message-as-read)

## Introduction
<!-- end -->

`WMTInbox` is responsible for managing messages in the Inbox. The inbox is a simple one-way delivery system that allows you to deliver messages to the user.

<!-- begin box warning -->
Note: Before using `WMTInbox`, you need to have a `PowerAuth` object available and initialized with a valid activation. Without a valid `PowerAuth` activation, the service will return an error.
<!-- end -->

`WMTInbox` communicates with the [Mobile Token API](https://developers.wultra.com/components/enrollment-server/develop/documentation/Mobile-Token-API).

## Getting an Instance

The instance of the `WMTInbox` can be accessed after creating the main object of the SDK:

```dart
final mtoken = powerAuthInstance.createMobileToken();
final inbox = mtoken.inbox;
```

## Inbox Usage

### Get Number of Unread Messages

To get the number of unread messages, use the following code:

```dart
final countUnread = await mtoken.inbox.getUnreadCount();
```

### Get a List of Messages

Get a paged list of messages:

```dart
// Get page 0 of size 50, do not exclude unread messages
final messageList = await mtoken.inbox.getMessageList(0, 50, false);
```

### Get Message Detail

Each message has its unique identifier. To get the body of the message, use the following code:

```dart
final messageId = messageList[0].id;
final detail = await mtoken.inbox.getMessageDetail(messageId);
```

### Set Message as Read

To mark the message as read by the user, use the following code:

```dart
final messageId = messageList[0].id;
await mtoken.inbox.markRead(messageId);
```

Alternatively, you can mark all messages as read:

```dart
await mtoken.inbox.markAllRead();
```

## Read Next
  
- [Server Error Handling](./Server-Error-Handling.md)
