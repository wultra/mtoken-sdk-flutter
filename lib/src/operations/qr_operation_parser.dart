import 'dart:convert';

import 'qr_operation.dart';
import '../core/logger.dart';

/// Parser for offline QR operations.
class WMTQROperationParser {
  
  // Minimum lines in input string supported by this parser.
  static const int _minimumAttributeFields = 7;

  // Current number of lines in input string, supported by this parser.
  static const int _currentAttributeFields = 8;

  // Maximum number of operation data fields supported in this version.
  static const int _maximumDataFields = 6;

  /// Process loaded payload from a scanned offline QR.
  ///
  /// @param [string] String parsed from QR code.
  ///
  /// @throws [WMTException] When there is no operation in provided string.
  /// @returns Parsed operation.
  static WMTQROperation parse(String string) {
    // Split string by newline
    final attributes = string.split("\n");

    if (attributes.length < _minimumAttributeFields) {
      throw WMTLogger.errorAndException("Offline operation: QR operation needs to have at least ${_minimumAttributeFields} attributes but have ${attributes.length}");
    }

    // Acquire all attributes
    final operationId = attributes[0];
    final title = _parseAttributeText(attributes[1]);
    final message = _parseAttributeText(attributes[2]);
    final dataString = attributes[3];
    final flagsString = attributes[4];
    final totp = attributes.length > _minimumAttributeFields ? attributes[5] : null;

    // Signature and nonce are always located at last lines
    final nonce = attributes[attributes.length - 2];
    final signatureString = attributes[attributes.length - 1];

    // Validate operationId
    if (operationId.isEmpty) {
      throw WMTLogger.errorAndException("Offline operation: QR operation ID is empty!.");
    }

    final signature = _parseSignature(signatureString);

    // validate nonce
    final nonceByteArray = base64Decode(nonce);
    if (nonceByteArray.length != 16) {
        throw WMTLogger.errorAndException("Offline operation: Invalid nonce data length (${nonceByteArray.length})");
    }

    // Parse operation data fields
    final operationData = _parseOperationData(dataString);

    // Rebuild signed data, without pure signature string
    final signedData = string.substring(0, string.length - signature.signatureString.length);

    // Parse flags
    final flags = _parseOperationFlags(flagsString);
    final isNewerFormat = attributes.length > _currentAttributeFields;

    return WMTQROperation(
      operationId: operationId, 
      title: title, 
      message: message, 
      operationData: operationData, 
      nonce: nonce, 
      flags: flags, 
      signedData: signedData, 
      signature: signature,
      isNewerFormat: isNewerFormat,
      totp: totp
      );
  }

  static String _parseAttributeText(String text) {
    if (text.contains("\\")) {
        return text.replaceAll("\\n", "\n").replaceAll("\\\\", "\\").replaceAll("\\*", "*");
    }
    return text;
  }

  /// Returns operation signature object if provided string contains valid key type and signature.
  static WMTQROperationSignature _parseSignature(String signaturePayload) {
    if (signaturePayload.isEmpty) {
      throw WMTLogger.errorAndException("Empty offline operation signature");
    }
    final rawKey = signaturePayload[0];
    final signingKey = WMTSigningKey.fromSerialized(rawKey);
    if (signingKey == null) {
      throw WMTLogger.errorAndException("Invalid offline operation signature key: ${rawKey}");
    }
    final signatureBase64 = signaturePayload.substring(1);
    final signatureByteArray = base64Decode(signatureBase64);
    if (signatureByteArray.length < 64 || signatureByteArray.length > 255) {
      throw WMTLogger.errorAndException("Invalid offline operation signature data (length ${signatureByteArray.length})");
    }
    return WMTQROperationSignature(
      signature: signatureByteArray,
      signatureString: signatureBase64,
      signingKey: signingKey
    );
  }

  /// Parses and translates input string into `QROperationFormData` structure.
  static WMTQROperationData _parseOperationData(String string) {
    final stringFields = _splitOperationData(string);
    if (stringFields.isEmpty) {
      throw WMTLogger.errorAndException("No fields at all in the offline operation data");
    }

    // Get and check version
    final versionString = stringFields[0];
    if (versionString.length < 2) {
        throw WMTLogger.errorAndException("Version string needs to be at least 2 characters long ('${versionString}' provided instead)");
    }

    final versionChar = versionString.codeUnitAt(0);

    if (versionChar < 'A'.codeUnitAt(0) || versionChar > 'Z'.codeUnitAt(0)) {
        throw WMTLogger.errorAndException("Offline operation: Version has to be an one capital letter (${versionChar} provided instead)");
    }
    final version = WMTQROperationDataVersion.fromSerialized(versionString);

    final templateIdString = versionString.substring(1);
    final templateId = int.tryParse(templateIdString);

    if (templateId == null) {
        throw WMTLogger.errorAndException("Offline operation: TemplateID is not an integer: ${templateIdString}");
    }

    if (templateId < 0 || templateId > 99) {
        throw WMTLogger.errorAndException("OfflineOperation: TemplateID is out of range ${templateId}.");
    }

    // Parse operation data fields
    final fields = _parseDataFields(stringFields);

    // Everything looks good, so build a final structure now...
    return WMTQROperationData(version: version, templateId: templateId, fields: fields, sourceString: string);
  }

  /// Splits input string into array of strings, representing array of form fields.
  /// It's expected that input string contains asterisk separated list of fields.
  static List<String> _splitOperationData(String string) {
    // Split string by '*'
    final components = string.split("*");
    final List<String> fields = [];
    // Handle escaped asterisk \* in array. This situation is easily detectable
    // by backslash at the end of the string.
    var appendNext = false;
    for (var substring in components) {
      if (appendNext) {
        // Previous string ended with backslash
        if (fields.isNotEmpty) {
          var prev = fields[fields.length -1];
          // Remove backslash from last stored value and append this new sequence
          prev = prev.substring(0, prev.length - 1);
          prev = "${prev}*${substring}";
          // Replace last element with updated string
          fields[fields.length - 1] = prev;
        }
      } else {
        // Just append this string into final array
        fields.add(substring);
      }
      // Check if current sequence ends with backslash
      appendNext = substring.isNotEmpty && substring[substring.length - 1] == '\\';
    }
    return fields;
  }

  /// Parses input string into array of Field enumerations.
  /// Throws a `WMTException` error if the resulting operation parses out with too many fields.
  static List<WMTQROperationDataField> _parseDataFields(List<String> fields) {

    final List<WMTQROperationDataField> result = [];

    fields.sublist(1).forEach((stringField) {

      final typeId = stringField.isNotEmpty ? stringField[0] : null;

      if (typeId == null) {
        result.add(WMTQROperationDataField(WMTQROperationDataFieldType.empty));
        return;
      }

      switch (typeId) {
        // Amount
        case 'A': 
          result.add(_parseAmount(stringField));
        // IBAN
        case 'I': 
          result.add(_parseIban(stringField));
        // Any account
        case 'Q': 
          result.add(WMTAnyAccountField(_parseFieldText(stringField)));
        // Date
        case 'D': 
          result.add(_parseDate(stringField));
        // Reference
        case 'R': 
          result.add(WMTReferenceField(_parseFieldText(stringField)));
        // Note
        case 'N': 
          result.add(WMTNoteField(_parseFieldText(stringField)));
        // Text (generic)
        case 'T': 
          result.add(WMTTextField(_parseFieldText(stringField)));
        // Fallback
        default: 
          result.add(WMTFallbackField(_parseFieldText(stringField), typeId));
      }
    });

    if (result.length > _maximumDataFields) {
      throw WMTLogger.errorAndException("Offline operation: Too many fields (${result.length})");
    }
    return result;
  }

  static WMTAmountField _parseAmount(String string) {
    final value = string.substring(1);
    if (value.length < 4) {
      throw WMTLogger.errorAndException("Offline operation: Insufficient length for number+currency (${value.length})");
    }
    final currency = value.substring(value.length - 3).toUpperCase();
    final amountString = value.substring(0, value.length - 3);
    final amount = double.tryParse(amountString);
    if (amount == null) {
      throw WMTLogger.errorAndException("Offline operation: Amount is not a number: ${amountString}");
    }
    return WMTAmountField(amount, currency);
  }

  // Parses IBAN[,BIC] into account field enumeration.
  static WMTAccountField _parseIban(String string) {
    // Try to split IBAN to IBAN & BIC
    final ibanBic = string.substring(1);
    final components = ibanBic.split(",").where((v) => v.isNotEmpty).toList();
    if (components.length > 2 || components.isEmpty) {
      throw WMTLogger.errorAndException("Offline operation: Unsupported format for IBAN: ${components}");
    }
    final iban = components[0];
    final bic = components.length > 1 ? components[1] : null;
    const allowedChars = "01234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    for (var i = 0; i < iban.length; i++) {
      final c = iban[i];
      if (!allowedChars.contains(c)) {
          throw WMTLogger.errorAndException("Invalid character in IBAN: ${c}");
      }
    }
    if (bic != null) {
      for (var i = 0; i < bic.length; i++) {
        final c = bic[i];
        if (!allowedChars.contains(c)) {
          throw WMTLogger.errorAndException("Invalid character in BIC: ${c}");
        }
      }
    }
    return WMTAccountField(iban, bic: bic);
  }

  static String _parseFieldText(String string) {
    final text = string.substring(1);
    if (text.contains("\\")) {
      // Replace escaped "\n" and "\\"
      return text.replaceAll("\\n", "\n").replaceAll("\\\\", "\\");
    }
    return text;
  }

  static WMTDateField _parseDate(String string) {

    final dateString = string.substring(1);
        
    if (dateString.length != 8) {
      throw WMTLogger.errorAndException("Offline operation: Date needs to be 8 characters long");
    }
    try {
      final year = int.tryParse(dateString.substring(0, 4));
      final month = int.tryParse(dateString.substring(4, 6));
      final day = int.tryParse(dateString.substring(6, 8));

      if (year == null || month == null || day == null) {
        throw WMTLogger.errorAndException("Offline operation: Year, month and day need to be integers. Year: ${year}, month: ${month}, day: ${day} from ${dateString}");
      }

      if (day < 1 || day > 31) {
        throw WMTLogger.errorAndException("Offline operation: Day needs to be between 1 and 31. Day: ${day}");
      }

      if (month < 1 || month > 12) {
        throw WMTLogger.errorAndException("Offline operation: Month needs to be between 1 and 12. Month: ${month}");
      }

      final date = DateTime(year, month, day);
      return WMTDateField(date);
    } catch (e) {
      throw WMTLogger.errorAndException("Offline operation: Unparseable date");
    }
  }

  static WMTQROperationFlags _parseOperationFlags(String string) {
    return WMTQROperationFlags(
      biometricsAllowed: string.contains("B"),
      flipButtons: string.contains("X"),
      fraudWarning: string.contains("F"),
      blockWhenOnCall: string.contains("C"),
    );
  }

}