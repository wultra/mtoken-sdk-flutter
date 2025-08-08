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
class WMTOperationProximityCheck {
    
  /// The actual Time-based one time password.
  final String totp;

  /// Type of the Proximity check.
  final WMTProximityCheckType type;

  /// Timestamp when the operation was scanned (qrCode) or delivered to the device (deeplink).
  final DateTime timestampReceived;

  /// Private constructor to create an instance of [WMTOperationProximityCheck].
  WMTOperationProximityCheck._({
    required this.totp,
    required this.type,
    required this.timestampReceived,
  });

  /// If you need to create an instance with a specific timestamp, you can use this factory constructor, 
  /// but we recommend accounting for the time synchronization to avoid potential issues with time discrepancies.
  ///
  /// Recommended usage is with [withSynchronizedTime] factory method instead, as it ensures that the timestamp 
  /// is synchronized with the server time.
  ///
  /// Params:
  /// - [totp] is the actual TOTP value.
  /// - [type] is the type of the proximity check.
  /// - [timestampReceived] is the time when the TOTP was received.
  factory WMTOperationProximityCheck.create({
    required String totp,
    required WMTProximityCheckType type,
    required DateTime timestampReceived,
  }) {
    return WMTOperationProximityCheck._(
      totp: totp,
      type: type,
      timestampReceived: timestampReceived,
    );
  }

  /// Creates a new instance of [WMTOperationProximityCheck] with [timestampReceived] automatically 
  /// set to current timestamp from server synchronized time.
  /// 
  /// This is a convenience method that uses the PowerAuth instance to get the current time for the [timestampReceived] field.
  ///
  /// Params:
  /// - [totp] is the actual TOTP value.
  /// - [type] is the type of the proximity check.
  /// - [powerAuth] is the PowerAuth instance used to get the synchronized time.
  static Future<WMTOperationProximityCheck> withSynchronizedTime({
    required String totp,
    required WMTProximityCheckType type,
    required PowerAuth powerAuth,
  }) async {
    final date = DateTime.fromMillisecondsSinceEpoch(await powerAuth.timeSynchronizationService.currentTime());
    return WMTOperationProximityCheck._(
      totp: totp,
      type: type,
      timestampReceived: date,
    );
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
