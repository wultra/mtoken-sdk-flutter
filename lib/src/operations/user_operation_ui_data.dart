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

/// Operation UI model that contains data for screens for pre and/or post approved operation.
class WMTUserOperationUIData {
  /// Confirm and Reject buttons should be flipped both in position and style.
  final bool? flipButtons;

  /// Block approval when on call (for example when on phone or skype call).
  final bool? blockApprovalOnCall;

  /// UI for pre-approval operation screen.
  final WMTPreApprovalScreen? preApprovalScreen;

  /// UI for post-approval operation screen.
  ///
  /// Type of PostApprovalScreen is presented with different classes based on its type (Starting with `PostApprovalScreen*`).
  /// 
  /// For example: WMTPostApprovalScreenRedirect that provides data after URL redirect.
  final WMTPostApprovalScreen? postApprovalScreen;

  WMTUserOperationUIData({
    this.flipButtons,
    this.blockApprovalOnCall,
    this.preApprovalScreen,
    this.postApprovalScreen,
  });

  /// Creates a [WMTUserOperationUIData] from a JSON map.
  factory WMTUserOperationUIData.fromJson(Map<String, dynamic> json) {
    return WMTUserOperationUIData(
      flipButtons: json['flipButtons'] as bool?,
      blockApprovalOnCall: json['blockApprovalOnCall'] as bool?,
      preApprovalScreen: json['preApprovalScreen'] != null
          ? WMTPreApprovalScreen.fromJson(json['preApprovalScreen'] as Map<String, dynamic>)
          : null,
      postApprovalScreen: json['postApprovalScreen'] != null
          ? WMTPostApprovalScreen.fromJson(json['postApprovalScreen'] as Map<String, dynamic>)
          : null,
    );
  }
}

class WMTPreApprovalScreen {
  /// Type of PreApprovalScreen ('WARNING', 'INFO', 'QR_SCAN').
  final String type;

  /// Heading of the pre-approval screen.
  final String heading;

  /// Message to the user.
  final String message;

  /// Array of items to be displayed as list of choices.
  final List<String>? items;

  /// Type of the approval button ('SLIDER' or 'BUTTON')
  final String? approvalType;

  WMTPreApprovalScreen({
    required this.type,
    required this.heading,
    required this.message,
    this.items,
    this.approvalType,
  });

  /// Creates a [WMTPreApprovalScreen] from a JSON map.
  factory WMTPreApprovalScreen.fromJson(Map<String, dynamic> json) {
    return WMTPreApprovalScreen(
      type: json['type'] as String,
      heading: json['heading'] as String,
      message: json['message'] as String,
      items: (json['items'] as List<dynamic>?)?.map((item) => item as String).toList(),
      approvalType: json['approvalType'] as String?,
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

// --- GENERIC PSOT APPROVAL ---

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
