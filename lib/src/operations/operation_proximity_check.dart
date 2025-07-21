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

