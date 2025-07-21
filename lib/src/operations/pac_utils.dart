import 'dart:convert';

import 'package:mtoken_sdk_flutter/src/utils/json_utils.dart';

import '../core/logger.dart';

/// Data payload which is returned from the parser.
class WMTPACData {

  /// The ID of the operation associated with the TOTP.
  String oid;

  /// The actual Time-based one time password (proximity OTP).
  String? potp;

  WMTPACData({
    required this.oid,
    this.potp,
  });
}

class WMTPACUtils {
  

  /// Method accepts deeplink URL and returns payload data or throws and exception.
  /// 
  /// Params: 
  ///  - [url] Deeplink URL
  /// 
  /// Returns data with parsed Proximity Antofraud Check data
  /// 
  /// Throws Exception when parsing failed
  static WMTPACData parseDeeplink(String url) {

    WMTLogger.info("Parsing PAC deeplink: ${url}");

    // Deeplink can have two query items with operationId & optional totp or single query item with JWT value

    final urlParams = _getURLParams(url);

    if (urlParams.containsKey("oid")) {

      final totp = urlParams["totp"] ?? urlParams["potp"];

      if (totp == null) {
        WMTLogger.info("TOTP not found in URL: ${url}");
      }

      return WMTPACData(
        oid: Uri.decodeComponent(urlParams["oid"]!),
        potp: totp != null ? Uri.decodeComponent(totp) : null
      );
    } else {
      final first = urlParams.entries.firstOrNull;

      if (first != null) {
        return _parseJWT(first.value);
      }

    throw WMTLogger.errorAndException("Failed to parse deeplink. Valid keys not found in URL: ${url}");
    }
  }

  /// Method accepts scanned code as a String and returns PAC data or throws an exception.
  /// 
  /// Params:
  ///  - [code] Code retrieved from the QR.
  /// 
  /// Returns data with parsed Proximity Antofraud Check data.
  /// Throws Exception when cannot be parsed.
  static WMTPACData parseQRCode(String code) {
    try {
      return parseDeeplink(code);
    } catch(e) {
      WMTLogger.info("Parsing JWT: ${code}");
      return _parseJWT(code);
    }
  }

  static WMTPACData _parseJWT(String code) {
    final jwtParts = code.split(".");
    if (jwtParts.length > 1) {
      // At this moment we don't care about header, we want only payload which is the second part of JWT
      final jwtBase64String = jwtParts[1];
      if (jwtBase64String.isNotEmpty) {
        try {
          final decoded = decodeBase64Safe(jwtBase64String);
          final json = jsonDecode(decoded);
          if (json['oid'] != null) {
            return WMTPACData(
              oid: json['oid'],
              potp: json['potp'],
            );
          } else {
            throw WMTLogger.errorAndException("Failed to decode QR JWT from: ${code}");
          }
        } catch (e) {
          throw WMTLogger.errorAndException("Failed to decode QR JWT from: ${code}. With error: ${e}");
        }
      }
    } else {
      throw WMTLogger.errorAndException("JWT Payload is empty, jwtParts contain: ${jwtParts}");
    }
    throw WMTLogger.errorAndException("Failed to decode QR JWT from: ${code}");
  }

  static Map<String, String> _getURLParams(String url) {
    final regex = RegExp(r'[?&]([^=#]+)=([^&#]*)');
    final params = <String, String>{};
    final matches = regex.allMatches(url);
    for (final match in matches) {
      params[match.group(1)!] = match.group(2)!;
    }
    return params;
  }
}