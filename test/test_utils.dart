import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

/// Creates a PowerAuth instance for testing.
///
/// The instance uses a dummy instanceId and should only be used
/// with components that accept a `timeProvider` override (like
/// [WMTPreApprovalScreensRecorder]) so the platform channel is never called.
PowerAuth mockPowerAuth() => PowerAuth('test-instance');
