/*
 * Copyright 2025 Wultra s.r.o.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:meta/meta.dart';

/// Object that is used to hold data about a proximity check.
/// Data shall be assigned to the operation when obtained.
///
/// The SDK automatically adjusts [timestampReceived] using server-synchronized time
/// during the operation authorization, so consumers only need to create this object
/// with [totp] and [type].
class WMTOperationProximityCheck {
  /// The actual Time-based one time password.
  final String totp;

  /// Type of the Proximity check.
  final WMTProximityCheckType type;

  /// Timestamp when the operation was scanned (qrCode) or delivered to the device (deeplink).
  ///
  /// Captured automatically as the current system time at creation. The SDK adjusts
  /// this value to the server time internally during operation authorization.
  final DateTime timestampReceived;

  /// Creates a new instance of [WMTOperationProximityCheck].
  ///
  /// The [timestampReceived] is captured automatically as the current system time. The SDK
  /// adjusts it using server-synchronized time during operation authorization.
  ///
  /// Params:
  /// - [totp] is the actual TOTP value.
  /// - [type] is the type of the proximity check.
  WMTOperationProximityCheck({required this.totp, required this.type})
    : timestampReceived = DateTime.now();

  /// Creates a WMTOperationProximityCheck, ignoring the provided [timestampReceived] parameter.
  ///
  /// The [timestampReceived] parameter is ignored — the SDK captures the current time at creation
  /// and adjusts it to server time internally during operation authorization. Custom timestamps
  /// are not supported because the SDK can only correct the system clock offset, not arbitrary
  /// values provided by the consumer.
  ///
  /// Params:
  /// - [totp] is the actual TOTP value.
  /// - [type] is the type of the proximity check.
  /// - [timestampReceived] Ignored. The SDK uses the current time and adjusts it during operation authorization.
  @Deprecated(
    "Use WMTOperationProximityCheck(totp: totp, type: type) instead. The SDK now handles time synchronization internally during authorize.",
  )
  factory WMTOperationProximityCheck.create({
    required String totp,
    required WMTProximityCheckType type,
    @Deprecated("This parameter is ignored. Use WMTOperationProximityCheck(totp: totp, type: type) instead.")
    DateTime? timestampReceived,
  }) {
    return WMTOperationProximityCheck(totp: totp, type: type);
  }

  /// Deprecated. Previously synchronized [timestampReceived] with the PowerAuth server.
  ///
  /// This is no longer needed — the SDK now handles time synchronization internally during
  /// operation authorization. This method simply creates a [WMTOperationProximityCheck]
  /// with the current time as the timestamp; the [powerAuth] parameter is ignored.
  ///
  /// Params:
  /// - [totp] is the actual TOTP value.
  /// - [type] is the type of the proximity check.
  /// - [powerAuth] is the PowerAuth instance (no longer used).
  @Deprecated(
    "No longer needed. The SDK automatically synchronizes time during authorization. Use WMTOperationProximityCheck(totp: totp, type: type) instead.",
  )
  static Future<WMTOperationProximityCheck> withSynchronizedTime({
    required String totp,
    required WMTProximityCheckType type,
    required PowerAuth powerAuth,
  }) async {
    return WMTOperationProximityCheck(totp: totp, type: type);
  }
}

/// Type of the Proximity check.
enum WMTProximityCheckType {
  /// TOTP delivered via QR code.
  qrCode("QR_CODE"),

  /// TOTP delivered via deep link.
  deeplink("DEEPLINK");

  @internal
  final String serialized;
  const WMTProximityCheckType(this.serialized);
}
