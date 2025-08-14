# Wultra Mobile Token Flutter SDK

__Wultra Mobile Token Flutter SDK__ is a high-level SDK for operation approval.

## Introduction
 
With Wultra Mobile Token (WMT) SDK, you can integrate an out-of-band operation approval into an existing mobile app, instead of using a standalone mobile token application. WMT is built on top of [PowerAuth Mobile Flutter SDK](https://github.com/wultra/flutter-powerauth-mobile-sdk). Individual endpoints are described in the [Mobile Token API](https://developers.wultra.com/components/enrollment-server/develop/documentation/Mobile-Token-API).

To understand the Wultra Mobile Token SDK purpose on a business level better, you can visit our own [Mobile Token application](https://www.wultra.com/mobile-token). We use (native) Wultra Mobile Token SDK in our mobile token application as well.

What you can do with Wultra Mobile Token SDK:

- Retrieve the list or detail of user operations.
- Approve or reject operations with PowerAuth transaction signing.
- Get operation history for a given user.
- Register an existing PowerAuth activation to receive push notifications.
- Fetch messages from the user's inbox.

Remarks:

- This library does not contain any UI.
- We also provide an [Android](https://github.com/wultra/mtoken-sdk-android), [iOS](https://github.com/wultra/mtoken-sdk-ios) and [Mobile JS](https://github.com/wultra/mtoken-sdk-js) version of this library.

## Open Source Code

The code of the library is open source and you can freely browse it in our GitHub at [https://github.com/wultra/mtoken-sdk-flutter](https://github.com/wultra/mtoken-sdk-flutter/#docucheck-keep-link)

<!-- begin remove -->
## Integration Tutorials

**Tutorials**

- [SDK Integration](./SDK-Integration.md)
- [Example Usage](./Example-Usage.md)
- [Using Operations](./Using-Operations.md)
- [Using Push](./Using-Push.md)
- [Using Inbox](./Using-Inbox.md)
- [Language and User-Agent Configuration](./Language-UserAgent-Configuration.md)

**Other**

- [Changelog](./Changelog.md)
<!-- end -->

## Support and compatibility

| Version | Flutter PowerAuth Flutter SDK | Flutter Version | Support Status  |
|---------|-------------------------------|-----------------|-----------------|
| `1.0.x` | `^1.1.0`                      | `3.3.0+`        | Fully supported |

## License

All sources are licensed using the Apache 2.0 license. You can use them with no restrictions. If you are using this library, please let us know. We will be happy to share and promote your project.

## Contact

If you need any assistance, do not hesitate to drop us a line at [hello@wultra.com](mailto:hello@wultra.com) or our official [wultra.com/discord](wultra.com/discord) channel.

### Security Disclosure

If you believe you have identified a security vulnerability with Wultra Mobile Token SDK, you should report it as soon as possible via email to [support@wultra.com](mailto:support@wultra.com). Please do not post it to a public issue tracker.
