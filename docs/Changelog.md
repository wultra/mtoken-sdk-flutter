# Changelog

## 2.0.0-beta.1

- Updated to PowerAuth Mobile Flutter SDK 2.0 and migrated request signing, offline signing, server signature verification, and end-to-end encryption to the new APIs.
- Updated minimum requirements to Flutter 3.44, Dart 3.12, Android 6.0 (API 23), Android compile SDK 37, and Java 17.
- Changed `WultraMobileToken.create()` and `PowerAuth.createMobileToken()` to asynchronous APIs.
- Added offline QR signature key `2` support for PowerAuth protocol V4 personalized KMAC signatures.
- Added OIDC activation [(#7)](https://github.com/wultra/mtoken-sdk-flutter/issues/7)
- Added support for UserOperation attribute type Alert [(#15)](https://github.com/wultra/mtoken-sdk-flutter/issues/15)
- Added Pre-Approval Screens and WMTPreApprovalScreensRecorder/Mobile Token data support [(#27)](https://github.com/wultra/mtoken-sdk-flutter/issues/27)
- Improved proximity check time handling, timestamps are now adjusted to server-synchronized time automatically during authorization [(#36)](https://github.com/wultra/mtoken-sdk-flutter/issues/36)
- Added periodic operation polling with loading, failure, and operation-change callbacks [(#34)](https://github.com/wultra/mtoken-sdk-flutter/issues/34)

## 1.0.0

- Initial release of the Wultra Mobile Token Flutter SDK 🎉
