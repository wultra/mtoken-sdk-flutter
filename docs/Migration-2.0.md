# Migration from 1.0.x to 2.0.x

This guide provides instructions for migrating from **Wultra Mobile Token SDK for Flutter** version `1.0.x` to version `2.0.x`.

## Pre-Approval Screen API

The singular `preApprovalScreen` property on `WMTUserOperationUIData` has been replaced by the plural `preApprovalScreens` list to support multi-screen pre-approval flows.

### Reading

```dart
// Before (1.0.x)
final screen = operation.ui?.preApprovalScreen;

// After (2.0.x)
final screens = operation.ui?.preApprovalScreens;
final firstScreen = screens?.first;
```

### Constructing

The `preApprovalScreen` constructor parameter has been removed. Use `preApprovalScreens` (a `List<WMTPreApprovalScreen>`) instead.

```dart
// Before (1.0.x)
final uiData = WMTUserOperationUIData(
  preApprovalScreen: myScreen,
  // ...
);

// After (2.0.x)
final uiData = WMTUserOperationUIData(
  preApprovalScreens: [myScreen],
  // ...
);
```
