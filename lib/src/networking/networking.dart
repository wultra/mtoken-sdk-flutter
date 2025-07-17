import 'dart:convert';
import 'dart:io';

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:meta/meta.dart';
import 'package:mtoken_sdk_flutter/src/core/exception.dart';
import '../core/logger.dart';
import 'known_rest_api_error.dart';
import '../networking/user_agent.dart';

typedef WMTRequestProcessor = void Function(HttpHeaders);

class WMTNetworking {
  
  String _acceptLanguage = "en";

  // Returns accept language for the outgoing requests.
  String get acceptLanguage => _acceptLanguage;

  set acceptLanguage(String language) {
    _acceptLanguage = language;
    WMTLogger.info("Accept language set to: ${language}.");
  }

  WMTUserAgent userAgent = WMTUserAgent.libraryDefault();

  @protected
  final PowerAuth powerAuth;
  final String _baseUrl;

  WMTNetworking(this.powerAuth, String baseUrl)
        : _baseUrl = baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  @internal
  Future<dynamic> postSigned(
    Object requestData,
    PowerAuthAuthentication auth,
    String endpoindPath,
    String uriId,
    { WMTRequestProcessor? requestProcessor }
  ) async {

    final body = jsonEncode(requestData);
    final paHeader = await powerAuth.requestSignature(auth, "POST", uriId, body);

    final headers = {
      paHeader.key: paHeader.value
    };

    return await post(body, endpoindPath, headers, requestProcessor);
  }

  @internal
  Future<dynamic> postSignedWithToken(
    Object requestData,
    PowerAuthAuthentication auth,
    String endpoindPath,
    String tokenName,
    { WMTRequestProcessor? requestProcessor }
  ) async {

        final body = jsonEncode(requestData);
        final token = await powerAuth.tokenStore.requestAccessToken(tokenName, auth);
        final paHeader = await powerAuth.tokenStore.generateHeaderForToken(token.tokenName);

        final headers = {
          paHeader.key: paHeader.value
        };

        return await post(body, endpoindPath, headers, requestProcessor);
    }

  @internal
  Future<dynamic> post(
    String paylodeSerialized,
    String endpointPath,
    Map<String, String> headers,
    WMTRequestProcessor? requestProcessor
  ) async {

    final client = HttpClient();

    try {

      final url = "${_baseUrl}${endpointPath}";
      final jsonType = "application/json";

      // Only POST method is supported for now.
      final request = await client.postUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.contentTypeHeader, jsonType);
      request.headers.set(HttpHeaders.acceptHeader, jsonType);
      request.headers.set(HttpHeaders.acceptLanguageHeader, _acceptLanguage);

      final userAgentValue = await userAgent.get();
      if (userAgentValue != null) {
        request.headers.set(HttpHeaders.userAgentHeader, userAgentValue);
      }

      headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      request.write(paylodeSerialized);

      if (requestProcessor != null) {
        requestProcessor(request.headers);
      }

      WMTLogger.info(" -> OUTGOING POST ${url}");
      if (WMTLogger.verbosity.level >= WMTLoggerVerbosity.verbose.level) {
        WMTLogger.verbose(_getHeadersString(request.headers));
        WMTLogger.verbose(paylodeSerialized);
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      WMTLogger.info(" <-- INCOMMING POST ${url}");
      if (WMTLogger.verbosity.level >= WMTLoggerVerbosity.verbose.level) {
        WMTLogger.verbose(_getHeadersString(response.headers));
        WMTLogger.verbose(responseBody);
      }

      final data = jsonDecode(responseBody);

      final responseObject = data["responseObject"];

      if (data["status"] != "OK") {
        final error = WMTResponseError.fromJson(responseObject as Map<String, dynamic>);
        throw WMTException(description: "Error response: ${error.message} (code: ${error.code})");
      }

      return responseObject;

    } finally {
      client.close();
    }
  }

  String _getHeadersString(HttpHeaders headers) {
    var result = "Headers: {";
    headers.forEach((String k, List<String> v) {
        result += ' "${k}": "${v.join(", ")}",';
    });
    return "${result}}";
  }
}
  
/// Error object when error on the server happens.
class WMTResponseError {
  /// Error code, which is one of the [WMTKnownRestApiError] values.
  WMTKnownRestApiError code;
  /// Error message, which is usually localized message for the user.
  String message;

  WMTResponseError(this.code, this.message);

  factory WMTResponseError.fromJson(Map<String, dynamic> json) {
    final code = WMTKnownRestApiError.fromCode(json['code'] as String);
    return WMTResponseError(code, json['message'] as String);
  }
}