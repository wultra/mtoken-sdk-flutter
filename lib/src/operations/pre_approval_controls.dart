/*
 * Copyright 2026 Wultra s.r.o.
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

/// Layout axis for pre-approval control buttons.
enum WMTPreApprovalButtonAxis {
  horizontal('HORIZONTAL'),
  vertical('VERTICAL');

  final String serialized;
  const WMTPreApprovalButtonAxis(this.serialized);

  static WMTPreApprovalButtonAxis? fromSerialized(String? value) {
    if (value == null) return null;
    // Cast to nullable list so firstWhere can return null via orElse
    return WMTPreApprovalButtonAxis.values.cast<WMTPreApprovalButtonAxis?>().firstWhere(
      (e) => e!.serialized == value,
      orElse: () => null,
    );
  }
}

/// Type of the decline control.
enum WMTPreApprovalDeclineType {
  back('BACK'),
  reject('REJECT');

  final String serialized;
  const WMTPreApprovalDeclineType(this.serialized);

  static WMTPreApprovalDeclineType? fromSerialized(String? value) {
    if (value == null) return null;
    return WMTPreApprovalDeclineType.values.cast<WMTPreApprovalDeclineType?>().firstWhere(
      (e) => e!.serialized == value,
      orElse: () => null,
    );
  }
}

/// Type of the approve control.
enum WMTPreApprovalApproveType {
  button('BUTTON'),
  slider('SLIDER');

  final String serialized;
  const WMTPreApprovalApproveType(this.serialized);

  static WMTPreApprovalApproveType? fromSerialized(String? value) {
    if (value == null) return null;
    return WMTPreApprovalApproveType.values.cast<WMTPreApprovalApproveType?>().firstWhere(
      (e) => e!.serialized == value,
      orElse: () => null,
    );
  }
}

/// Configuration of approve/decline controls for a pre-approval screen.
class WMTPreApprovalControls {
  /// Whether approve and decline buttons should be swapped in position.
  final bool? flip;

  /// Layout axis: HORIZONTAL or VERTICAL.
  final WMTPreApprovalButtonAxis? axis;

  /// Decline control specification.
  final WMTPreApprovalDecline? decline;

  /// Approve control specification.
  final WMTPreApprovalApprove? approve;

  WMTPreApprovalControls({
    this.flip,
    this.axis,
    this.decline,
    this.approve,
  });

  factory WMTPreApprovalControls.fromJson(Map<String, dynamic> json) {
    return WMTPreApprovalControls(
      flip: json['flip'] as bool?,
      axis: WMTPreApprovalButtonAxis.fromSerialized(json['axis'] as String?),
      decline: json['decline'] != null
          ? WMTPreApprovalDecline.fromJson(json['decline'] as Map<String, dynamic>)
          : null,
      approve: json['approve'] != null
          ? WMTPreApprovalApprove.fromJson(json['approve'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Decline control configuration.
class WMTPreApprovalDecline {
  /// Type of decline action: BACK or REJECT.
  final WMTPreApprovalDeclineType? type;

  /// Custom label for the decline button.
  final String? text;

  WMTPreApprovalDecline({this.type, this.text});

  factory WMTPreApprovalDecline.fromJson(Map<String, dynamic> json) {
    return WMTPreApprovalDecline(
      type: WMTPreApprovalDeclineType.fromSerialized(json['type'] as String?),
      text: json['text'] as String?,
    );
  }
}

/// Approve control configuration.
class WMTPreApprovalApprove {
  /// Type of approve action: BUTTON or SLIDER.
  final WMTPreApprovalApproveType? type;

  /// Custom label for the approve button.
  final String? text;

  /// Countdown in seconds before the approve control becomes active.
  final int? counter;

  WMTPreApprovalApprove({this.type, this.text, this.counter});

  factory WMTPreApprovalApprove.fromJson(Map<String, dynamic> json) {
    return WMTPreApprovalApprove(
      type: WMTPreApprovalApproveType.fromSerialized(json['type'] as String?),
      text: json['text'] as String?,
      counter: json['counter'] as int?,
    );
  }
}
