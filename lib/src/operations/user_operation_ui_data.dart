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

import 'user_operation_attribute.dart';
import 'pre_approval_element.dart';
import 'pre_approval_controls.dart';

/// Operation UI model that contains data for screens for pre and/or post approved operation.
class WMTUserOperationUIData {
  /// Confirm and Reject buttons should be flipped both in position and style.
  final bool? flipButtons;

  /// Block approval when on call (for example when on phone or skype call).
  final bool? blockApprovalOnCall;

  /// Pre-approval screens to display before the operation can be approved.
  ///
  /// May contain multiple screens that the user must go through.
  /// When the backend provides the legacy single `preApprovalScreen`,
  /// it is automatically converted to a single-element list.
  final List<WMTPreApprovalScreen>? preApprovalScreens;

  /// UI for pre-approval operation screen.
  ///
  /// Convenience getter returning the first pre-approval screen (if any).
  /// Use [preApprovalScreens] for the full list.
  @Deprecated('Use preApprovalScreens instead')
  WMTPreApprovalScreen? get preApprovalScreen =>
      preApprovalScreens != null && preApprovalScreens!.isNotEmpty
          ? preApprovalScreens!.first
          : null;

  /// UI for post-approval operation screen.
  ///
  /// Type of PostApprovalScreen is presented with different classes based on its type (Starting with `PostApprovalScreen*`).
  /// 
  /// For example: WMTPostApprovalScreenRedirect that provides data after URL redirect.
  final WMTPostApprovalScreen? postApprovalScreen;

  WMTUserOperationUIData({
    this.flipButtons,
    this.blockApprovalOnCall,
    this.preApprovalScreens,
    this.postApprovalScreen,
  });

  /// Creates a [WMTUserOperationUIData] from a JSON map.
  ///
  /// Supports both the new `preApprovalScreens` (plural, array) format
  /// and the legacy `preApprovalScreen` (singular) format.
  /// When the legacy format is detected, it is converted to the new model.
  factory WMTUserOperationUIData.fromJson(Map<String, dynamic> json) {
    List<WMTPreApprovalScreen>? screens;
    if (json['preApprovalScreens'] != null) {
      screens = (json['preApprovalScreens'] as List<dynamic>)
          .map((s) => WMTPreApprovalScreen.fromJson(s as Map<String, dynamic>))
          .toList();
    } else if (json['preApprovalScreen'] != null) {
      screens = [WMTPreApprovalScreen._fromLegacyJson(json['preApprovalScreen'] as Map<String, dynamic>)];
    }

    return WMTUserOperationUIData(
      flipButtons: json['flipButtons'] as bool?,
      blockApprovalOnCall: json['blockApprovalOnCall'] as bool?,
      preApprovalScreens: screens,
      postApprovalScreen: json['postApprovalScreen'] != null
          ? WMTPostApprovalScreen.fromJson(json['postApprovalScreen'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Pre-approval screen model with configurable elements and controls.
class WMTPreApprovalScreen {
  /// Type of the screen ('WARNING', 'INFO', 'QR_SCAN').
  final String type;

  /// Heading of the pre-approval screen.
  final String heading;

  /// Message to the user.
  final String message;

  /// Optional unique identifier of the screen.
  final String? id;

  /// Whether to show a back button instead of a decline/reject button.
  final bool? backButton;

  /// Asset identifier for the screen image.
  final String? image;

  /// Structured elements that form the screen content.
  ///
  /// Elements can be [WMTPreApprovalElementListItem], [WMTPreApprovalElementAlert],
  /// or [WMTPreApprovalElementButton].
  final List<WMTPreApprovalElement>? elements;

  /// Configuration of approve/decline controls.
  final WMTPreApprovalControls? controls;

  WMTPreApprovalScreen({
    required this.type,
    required this.heading,
    required this.message,
    this.id,
    this.backButton,
    this.image,
    this.elements,
    this.controls,
  });

  /// Creates a [WMTPreApprovalScreen] from the new JSON format.
  factory WMTPreApprovalScreen.fromJson(Map<String, dynamic> json) {
    return WMTPreApprovalScreen(
      type: json['type'] as String,
      heading: json['heading'] as String,
      message: json['message'] as String,
      id: json['id'] as String?,
      backButton: json['backButton'] as bool?,
      image: json['image'] as String?,
      elements: (json['elements'] as List<dynamic>?)
          ?.map((e) => WMTPreApprovalElement.fromJson(e as Map<String, dynamic>))
          .toList(),
      controls: json['controls'] != null
          ? WMTPreApprovalControls.fromJson(json['controls'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Converts the legacy single pre-approval screen format to the new model.
  ///
  /// Legacy `items` are mapped to [WMTPreApprovalElementListItem] elements
  /// and `approvalType` is mapped to [WMTPreApprovalControls].
  factory WMTPreApprovalScreen._fromLegacyJson(Map<String, dynamic> json) {
    final legacyItems = (json['items'] as List<dynamic>?)?.map((item) => item as String).toList();
    final legacyApprovalType = json['approvalType'] as String?;

    // Convert legacy items to ListItem elements
    List<WMTPreApprovalElement>? elements;
    if (legacyItems != null && legacyItems.isNotEmpty) {
      elements = legacyItems.map((item) => WMTPreApprovalElementListItem(
        text: item,
        icon: 'fallback_icon',
      )).toList();
    }

    // Convert legacy approvalType to controls
    WMTPreApprovalControls? controls;
    if (legacyApprovalType != null) {
      controls = WMTPreApprovalControls(
        approve: WMTPreApprovalApprove(
          type: WMTPreApprovalApproveType.fromSerialized(legacyApprovalType),
        ),
      );
    }

    return WMTPreApprovalScreen(
      type: json['type'] as String,
      heading: json['heading'] as String,
      message: json['message'] as String,
      image: 'fallback_image',
      elements: elements,
      controls: controls,
    );
  }
}

class WMTPostApprovalScreen {
  /// Type of PostApprovalScreen is presented with different classes (Starting with `PostApprovalScreen*`).
  /// 
  /// "REVIEW" | "REDIRECT" | "GENERIC"
  final String type;

  WMTPostApprovalScreen({required this.type});

  /// Creates a [WMTPostApprovalScreen] from a JSON map.
  factory WMTPostApprovalScreen.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'REVIEW':
        return WMTPostApprovalScreenReview.fromJson(json);
      case 'REDIRECT':
        return WMTPostApprovalScreenRedirect.fromJson(json);
      case 'GENERIC':
        return WMTPostApprovalScreenGeneric.fromJson(json);
      default:
        throw ArgumentError('Unknown PostApprovalScreen type: $type');
    }
  }
}

// --- REVIEW POST APPROVAL ---

class WMTPostApprovalScreenReview extends WMTPostApprovalScreen {
  /// Heading of the post-approval screen.
  final String heading;

  /// Message to the user.
  final String message;

  /// Payload with data for the review.
  final WMTReviewPostApprovalScreenPayload payload;

  WMTPostApprovalScreenReview({
    required this.heading,
    required this.message,
    required this.payload,
    required super.type
  });

  /// Creates a [WMTPostApprovalScreenReview] from a JSON map.
  factory WMTPostApprovalScreenReview.fromJson(Map<String, dynamic> json) {
    return WMTPostApprovalScreenReview(
      heading: json['heading'] as String,
      message: json['message'] as String,
      payload: WMTReviewPostApprovalScreenPayload.fromJson(json['payload'] as Map<String, dynamic>),
      type: json['type'] as String,
    );
  }
}

/// Review payload.
class WMTReviewPostApprovalScreenPayload {
  /// List of the operation attributes.
  final List<WMTUserOperationAttribute> attributes;

  WMTReviewPostApprovalScreenPayload({
    required this.attributes,
  });

  /// Creates a [WMTReviewPostApprovalScreenPayload] from a JSON map.
  factory WMTReviewPostApprovalScreenPayload.fromJson(Map<String, dynamic> json) {
    return WMTReviewPostApprovalScreenPayload(
      attributes: (json['attributes'] as List<dynamic>)
          .map((attr) => WMTUserOperationAttribute.fromJson(attr as Map<String, dynamic>))
          .toList(),
    );
  }
}

// --- REDIRECT POST APPROVAL ---

class WMTPostApprovalScreenRedirect extends WMTPostApprovalScreen {
  /// Heading of the post-approval screen.
  final String heading;

  /// Message to the user.
  final String message;

  /// Payload with data for the redirect.
  final WMTRedirectPostApprovalScreenPayload payload;

  WMTPostApprovalScreenRedirect({
    required this.heading,
    required this.message,
    required this.payload,
    required super.type,
  });

  /// Creates a [WMTPostApprovalScreenRedirect] from a JSON map.
  factory WMTPostApprovalScreenRedirect.fromJson(Map<String, dynamic> json) {
    return WMTPostApprovalScreenRedirect(
      heading: json['heading'] as String,
      message: json['message'] as String,
      payload: WMTRedirectPostApprovalScreenPayload.fromJson(json['payload'] as Map<String, dynamic>),
      type: json['type'] as String,
    );
  }
}

class WMTRedirectPostApprovalScreenPayload {
  /// Label of the redirect URL.
  final String redirectText;

  /// URL to redirect, might be a website or application.
  final String redirectUrl;

  /// Time in seconds before automatic redirect.
  final int countdown;

  WMTRedirectPostApprovalScreenPayload({
    required this.redirectText,
    required this.redirectUrl,
    required this.countdown,
  });

  /// Creates a [WMTRedirectPostApprovalScreenPayload] from a JSON map.
  factory WMTRedirectPostApprovalScreenPayload.fromJson(Map<String, dynamic> json) {
    return WMTRedirectPostApprovalScreenPayload(
      redirectText: json['redirectText'] as String,
      redirectUrl: json['redirectUrl'] as String,
      countdown: json['countdown'] as int,
    );
  }
}

// --- GENERIC POST APPROVAL ---

class WMTPostApprovalScreenGeneric extends WMTPostApprovalScreen {
  /// Heading of the post-approval screen.
  final String heading;

  /// Message to the user.
  final String message;

  /// Payload with data for the generic post-approval screen.
  final Map<String, dynamic> payload;

  WMTPostApprovalScreenGeneric({
    required this.heading,
    required this.message,
    required this.payload,
    required super.type,
  });

  /// Creates a [WMTPostApprovalScreenGeneric] from a JSON map.
  factory WMTPostApprovalScreenGeneric.fromJson(Map<String, dynamic> json) {
    return WMTPostApprovalScreenGeneric(
      heading: json['heading'] as String,
      message: json['message'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      type: json['type'] as String,
    );
  }
}
