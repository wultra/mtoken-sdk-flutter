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

import 'online_operation.dart';
import 'operation_proximity_check.dart';
import 'user_operation_attribute.dart';
import 'user_operation_ui_data.dart';

/// `UserOperation` is object returned from the backend that can be either approved or rejected.
/// It is usually visually presented to the user as a non-editable form with information about
/// the real-world operation (for example login or payment).
class WMTUserOperation extends WMTOnlineOperation {

    /// Unique identifier of the operation.
    @override
    final String id;

    /// Actual data that will be signed.
    /// 
    /// This shouldn't be visible to the user.
    @override
    final String data;

    /// Processing status of the operation.
    final WMTUserOperationStatus status;

    /// System name of the operation (for example login).
    /// 
    /// Name of the operation shouldn't be visible to the user. You can use it to distinguish how 
    /// the operation will be presented. (for example when the template for login is different than payment).
    final String name;
    
    /// Date and time when the operation was created. 
    final DateTime operationCreated;
    
    /// Date and time when the operation will expire.
    /// 
    /// You should never use this for hiding the operation (visually) from the user
    /// as the time set for the user system can differ with the backend. 
    final DateTime operationExpires;
    
    /// Data that should be presented to the user. 
    final WMTOperationFormData formData;
    
    /// Enum-like reason why the status has changed.
    /// 
    ///  Max 32 characters are expected. Possible values depend on the backend implementation and configuration. 
    final String? statusReason;
    
    /// Allowed signature types.
    /// 
    /// This hints if the operation needs a 2nd factor or can be approved simply by
    /// tapping an approve button. If the operation requires 2FA, this value also hints if
    /// the user may use the biometry, or if a password is required. 
    final WMTAllowedOperationSignature allowedSignatureType;
    
    /// UI data to be shown.
    ///
    /// Accompanying information about the operation additional UI which should be presented such as
    /// Pre-Approval Screen or Post-Approval Screen
    final WMTUserOperationUIData? ui;

    /// Proximity Check Data to be passed when OTP is handed to the app.
    /// 
    /// This data is not retrieved from the server but is set by the application.
    @override
    WMTOperationProximityCheck? proximityCheck;

    /// Additional mobile token data for authorization (available with PowerAuth server 1.10+)
    /// 
    /// This data is not retrieved from the server but is set by the application.
    @override
    Object? mobileTokenData;

    WMTUserOperation({
        required this.id,
        required this.data,
        required this.status,
        required this.name,
        required this.operationCreated,
        required this.operationExpires,
        required this.formData,
        required this.allowedSignatureType,
        this.ui,
        this.statusReason,
    });

    factory WMTUserOperation.fromJson(Map<String, dynamic> json) {
      return WMTUserOperation(
        id: json['id'] as String,
        data: json['data'] as String,
        status: WMTUserOperationStatus.fromSerialized(json['status'] as String),
        name: json['name'] as String,
        operationCreated: DateTime.parse(json['operationCreated'] as String),
        operationExpires: DateTime.parse(json['operationExpires'] as String),
        statusReason: json['statusReason'] as String?,
        formData: WMTOperationFormData.fromJson(json['formData'] as Map<String, dynamic>),
        ui: json['ui'] != null
            ? WMTUserOperationUIData.fromJson(json['ui'] as Map<String, dynamic>)
            : null,
        allowedSignatureType: WMTAllowedOperationSignature.fromJson(json['allowedSignatureType'] as Map<String, dynamic>)
      );
    }
}

enum WMTUserOperationStatus {
    approved("APPROVED"),
    rejected("REJECTED"),
    pending("PENDING"),
    canceled("CANCELED"),
    expired("EXPIRED"),
    failed("FAILED");
    
    final String _serialized;
    const WMTUserOperationStatus(this._serialized);

    /// Returns the [WMTUserOperationStatus] for the given serialized value, or null if not found.
    static WMTUserOperationStatus fromSerialized(String serialized) {
      return WMTUserOperationStatus.values.firstWhere(
        (status) => status._serialized == serialized
      );
    }
}

/// Signature type and variants that are allowed for the operation.
class WMTAllowedOperationSignature {
    /// If operation should be signed with 1 or 2 factor authentication.
    final WMTSignatureType type;

    /// What factors are needed to signing this operation.
    final List<WMTSignatureVariant> variants;

    WMTAllowedOperationSignature({
        required this.type,
        required this.variants
    });

    factory WMTAllowedOperationSignature.fromJson(Map<String, dynamic> json) {
      return WMTAllowedOperationSignature(
        type: WMTSignatureType.fromSerialized(json['type'] as String),
        variants: (json['variants'] as List<dynamic>)
            .map((variant) => WMTSignatureVariant.fromSerialized(variant as String))
            .toList(),
      );
    }
}

/// Factors that can be used for operation approval.
enum WMTSignatureVariant {
    possession("possession"),
    possessionKnowledge("possession_knowledge"),
    possessionBiometry("possession_biometry");

    final String _serialized;
    const WMTSignatureVariant(this._serialized);

    /// Returns the [WMTSignatureVariant] for the given serialized value, or null if not found.
    static WMTSignatureVariant fromSerialized(String serialized) {
      return WMTSignatureVariant.values.firstWhere(
        (variant) => variant._serialized == serialized
      );
    }
}

/// Allowed signature types that can be used for operation approval.
enum WMTSignatureType {
    oneFactor("1FA"),
    twoFactor("2FA");

    final String _serialized;
    const WMTSignatureType(this._serialized);

    /// Returns the [WMTSignatureType] for the given serialized value, or null if not found.
    static WMTSignatureType fromSerialized(String serialized) {
      return WMTSignatureType.values.firstWhere(
        (type) => type._serialized == serialized
      );
    }
}

/// Operation data, that should be visible to the user.
/// 
///  Note that the data returned from the server are localized based on the `MobileToken.acceptLanguage` property.
class WMTOperationFormData {
  /// Title of the operation.
  String title;

  /// Message for the user.
  String message;

  /// Texts for the result of the operation.
  /// 
  /// This includes messages for different outcomes of the operation such as success, rejection, and failure.
  WMTResultTexts? resultTexts;

  /// Other attributes.
  /// 
  /// Note that attributes can be presented with different classes (Starting with `MobileTokenOperationAttribute*`) based on the attribute type.
  List<WMTUserOperationAttribute> attributes;

  WMTOperationFormData({
    required this.title,
    required this.message,
    this.resultTexts,
    required this.attributes,
  });

  factory WMTOperationFormData.fromJson(Map<String, dynamic> json) {
    return WMTOperationFormData(
      title: json['title'] as String,
      message: json['message'] as String,
      resultTexts: json['resultTexts'] != null
          ? WMTResultTexts.fromJson(json['resultTexts'] as Map<String, dynamic>)
          : null,
      attributes: (json['attributes'] as List<dynamic>)
          .map((attr) => WMTUserOperationAttribute.fromJson(attr as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Texts for the result of the operation.
/// 
/// This includes messages for different outcomes of the operation such as success, rejection, and failure.
class WMTResultTexts {
  /// Optional message to be displayed when the approval of the operation is successful.
  String? success;

  /// Optional message to be displayed when the operation approval or rejection fails.
  String? failure;

  /// Optional message to be displayed when the operation is rejected.
  String? reject;

  WMTResultTexts({this.success, this.failure, this.reject});

  factory WMTResultTexts.fromJson(Map<String, dynamic> json) {
    return WMTResultTexts(
      success: json['success'] as String?,
      failure: json['failure'] as String?,
      reject: json['reject'] as String?,
    );
  }
}