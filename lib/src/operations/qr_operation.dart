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

import 'dart:typed_data';
import 'qr_operation_parser.dart';

/// Contains operation data parsed from the offline operation QR code.
class WMTQROperation {
  
  /// Operation's identifier.
  String operationId;
    
  /// Title associated with the operation.
  String title;
  
  /// Message associated with the operation.
  String message;
  
  /// Significant data fields associated with the operation.
  WMTQROperationData operationData;
  
  /// Nonce for offline signature calculation, in Base64 format.
  String nonce;
  
  /// Flags associated with the operation.
  WMTQROperationFlags flags;
  
  /// Additional Time-based one time password for proximity check.
  String? totp;
  
  /// Data for signature validation.
  String signedData;
  
  /// ECDSA signature calculated from `signedData`. String is in Base64 format.
  WMTQROperationSignature signature;
  
  /// QR code uses a string in newer format that this class implements.
  /// This flag may be used as warning, presented in UI.
  bool isNewerFormat;

  /// Data that will be used for the offline signature.
  String get dataForOfflineSining {
    return "${operationId}&${operationData.sourceString}${totp != null ? "&${totp}" : ""}";
  }

  WMTQROperation({
    required this.operationId,
    required this.title,
    required this.message,
    required this.operationData,
    required this.nonce,
    required this.flags,
    this.totp,
    required this.signedData,
    required this.signature,
    this.isNewerFormat = false,
  });

  /// Process loaded payload from a scanned offline QR.
  ///
  /// @param [qrString] String parsed from QR code.
  ///
  /// @throws [WMTException] When there is no operation in provided string.
  factory WMTQROperation.fromQRString(String qrString) {
    return WMTQROperationParser.parse(qrString);
  }
}

class WMTQROperationFlags {
  /// If true, then 2FA signature with biometric factor can be used for operation confirmation.
  bool biometricsAllowed;

  /// If confirm/reject buttons should be flipped in the UI. This can be useful to test users attention.
  bool flipButtons;

  /// When the operation is considered a "potential fraud" on the server, a warning UI should be displayed to the user.
  bool fraudWarning;

  /// Block confirmation when call is active.
  bool blockWhenOnCall;

  WMTQROperationFlags({
    this.biometricsAllowed = false,
    this.flipButtons = false,
    this.fraudWarning = false,
    this.blockWhenOnCall = false,
  });
}

class WMTQROperationData {

  /// Version of form data.
  WMTQROperationDataVersion version;

  /// Template identifier (0 .. 99 in v1).
  int templateId;

  /// Array with form fields. Version v1 supports up to 5 fields.
  List<WMTQROperationDataField> fields;

  /// A whole line from which was this structure constructed.
  String sourceString;

  WMTQROperationData({
    required this.version,
    required this.templateId,
    required this.fields,
    required this.sourceString,
  });
}

enum WMTQROperationDataVersion {
  /// First version of operation data.
  v1,
  /// Type representing all newer versions of operation data (for forward compatibility).
  vX; // inprobable character to act only as a fallback

  factory WMTQROperationDataVersion.fromSerialized(int serialized) {
    switch (serialized) {
      case 65: return WMTQROperationDataVersion.v1; // 'A' in ASCII
      default: return WMTQROperationDataVersion.vX;
    }
  }
}

enum WMTQROperationDataFieldType {
  /// Empty field for optional and not used fields.
  empty,
  /// Field is of type `AmountField`.
  amount,
  /// Field is of type `AccountField`.
  account,
  /// Field is of type `AnyAccountField`.
  anyAccount,
  /// Field is of type `DateField`.
  date,
  /// Field is of type `ReferenceField`.
  reference,
  /// Field is of type `NoteField`.
  note,
  /// Field is of type `TextField`.
  text,
  /// Field is of type `FallbackField`.
  fallback
}

class WMTQROperationDataField {
  WMTQROperationDataFieldType type;

  WMTQROperationDataField(this.type);
}

/// Amount with currency
class WMTAmountField extends WMTQROperationDataField {
  double amount;
  String currency;

  WMTAmountField(this.amount, this.currency) : super(WMTQROperationDataFieldType.amount);
}

/// Account in IBAN format, with optional BIC.
class WMTAccountField extends WMTQROperationDataField {
  String iban;
  String? bic;

  WMTAccountField(this.iban, {this.bic}) : super(WMTQROperationDataFieldType.account);
}

/// Account in arbitrary textual format.
class WMTAnyAccountField extends WMTQROperationDataField {
  String account;

  WMTAnyAccountField(this.account) : super(WMTQROperationDataFieldType.anyAccount);
}

/// Date field.
class WMTDateField extends WMTQROperationDataField {
  DateTime date;

  WMTDateField(this.date) : super(WMTQROperationDataFieldType.date);
}

/// Reference field
class WMTReferenceField extends WMTQROperationDataField {
  String reference;

  WMTReferenceField(this.reference) : super(WMTQROperationDataFieldType.reference);
}

/// Note field
class WMTNoteField extends WMTQROperationDataField {
  String note;

  WMTNoteField(this.note) : super(WMTQROperationDataFieldType.note);
}

/// Text field
class WMTTextField extends WMTQROperationDataField {
  String text;

  WMTTextField(this.text) : super(WMTQROperationDataFieldType.text);
}

/// Fallback field
class WMTFallbackField extends WMTQROperationDataField {
  String text;
  String rawType;

  WMTFallbackField(this.text, this.rawType) : super(WMTQROperationDataFieldType.fallback);
}

/// Model class for offline QR operation signature.
class WMTQROperationSignature {
  /// Defines which key has been used for ECDSA signature calculation.
  WMTSigningKey signingKey;

  /// Raw signature data.
  Uint8List signature;

  /// Signature in Base64 format.
  String signatureString;

  WMTQROperationSignature({
    required this.signingKey,
    required this.signature,
    required this.signatureString,
  });
}

/// Defines which key was used for ECDSA signature calculation.
enum WMTSigningKey {
  /// Master server key was used for ECDSA signature calculation.
  master,

  // Personalized server's private key was used for ECDSA signature calculation.
  personalized();

  static WMTSigningKey? fromSerialized(String serialized) {
    switch (serialized) {
      case "0": return WMTSigningKey.master;
      case "1": return WMTSigningKey.personalized;
      default: return null;
    }
  }
}
