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

/// Reason why the operation will be rejected
/// 
/// Possible reasons are:
/// - [WMTRejectionReason.unknown] - User doesn't want to provide the reason
/// - [WMTRejectionReason.incorrectData] - Operation data does not match (for example when user found a typo or other mistake)
/// - [WMTRejectionReason.unexpectedOperation] - User didn't started this operation
/// - [WMTRejectionReason.custom] - Represents a custom reason for rejection, allowing for flexibility in specifying rejection reasons.
class WMTRejectionReason {

  @internal
  final String serialized;

  WMTRejectionReason._(this.serialized);

  /// User doesn't want to provide the reason.
  factory WMTRejectionReason.unknown() {
    return WMTRejectionReason._("UNKNOWN");
  }

  /// Operation data does not match (for example when user found a typo or other mistake)
  factory WMTRejectionReason.incorrectData() {
    return WMTRejectionReason._("INCORRECT_DATA");
  }

  /// User didn't started this operation
  factory WMTRejectionReason.unexpectedOperation() {
    return WMTRejectionReason._("UNEXPECTED_OPERATION");
  }

  /// Represents a custom reason for rejection, allowing for flexibility in specifying rejection reasons.
  /// [reason] A string describing the custom rejection reason, e.g., `POSSIBLE_FRAUD`.
  factory WMTRejectionReason.custom(String reason) {
    return WMTRejectionReason._(reason);
  }
}