# Changelog

## X.Y.Z (TBA)

Added OIDC activation [(#7)](https://github.com/wultra/mtoken-sdk-flutter/issues/7)
Added support for UserOperation attribute type Alert [(#15)](https://github.com/wultra/mtoken-sdk-flutter/issues/15)
Added Pre-Approval Screens support ([documentation](Using-Operations.md#pre-approval-screens))
  - `WMTUserOperationUIData.preApprovalScreens` — array of `WMTPreApprovalScreen` with elements and controls
  - `WMTPreApprovalScreensRecorder` — records user navigation through pre-approval screens
  - `WMTMobileTokenDataBuilder` — builds structured data for approve/reject requests
  - `PREAPPROVAL` rejection reason for declining during pre-approval flow
  - `mobileTokenData` parameter on `reject()` method

## 1.0.0

- Initial SDK release
