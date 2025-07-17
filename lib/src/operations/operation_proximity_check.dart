import 'package:meta/meta.dart';

/// Object that is used to hold data about a proximity check.
/// Data shall be assigned to the operation when obtained.
class WMTOperationProximityCheck {

  // TODO: add test for serialization
    
  /// The actual Time-based one time password.
  final String totp;

  /// Type of the Proximity check.
  final WMTProximityCheckType type;

  /// Timestamp when the operation was scanned (qrCode) or delivered to the device (deeplink).
  final DateTime timestampReceived;

  WMTOperationProximityCheck({
    required this.totp,
    required this.type,
    required this.timestampReceived,
  });
}

enum WMTProximityCheckType {
  qrCode("QR_CODE"),
  deeplink("DEEPLINK");

  @internal
  final String serialized;
  const WMTProximityCheckType(this.serialized);
}

