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

import 'dart:convert';
import 'dart:io';

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:meta/meta.dart';
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
    Log.info("Accept language set to: ${language}.");
  }

  WMTUserAgent userAgent = WMTUserAgent.libraryDefault();

  @protected
  final PowerAuth powerAuth;
  final String _baseUrl;
  final String _name;

  WMTNetworking(this.powerAuth, String baseUrl, this._name)
        : _baseUrl = baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl {
    Log.verbose("Networking initialized for ${_name} with base URL: ${_baseUrl}.");
  }

  @internal
  Future<dynamic> postSigned(
    Object requestData,
    PowerAuthAuthentication auth,
    String endpoindPath,
    String uriId,
    { WMTRequestProcessor? requestProcessor }
  ) async {
    Log.verbose("Creating signed request for ${_name} with uriId: ${uriId}.");
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
    Log.verbose("Creating token signed request for ${_name}.");
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
    String payloadSerialized,
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

      request.write(payloadSerialized);

      if (requestProcessor != null) {
        requestProcessor(request.headers);
      }

      Log.info(" -> OUTGOING POST ${url}");
      Log.verbose(() => _getHeadersString(request.headers));
      Log.debug(payloadSerialized);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      Log.info(" <-- INCOMMING POST ${url}, status code ${response.statusCode}");
      Log.verbose(() => _getHeadersString(response.headers));
      Log.debug(responseBody);

      final data = jsonDecode(responseBody);

      final responseObject = data["responseObject"];

      if (data["status"] != "OK") {
        final error = WMTResponseError.fromJson(responseObject as Map<String, dynamic>);
        throw Log.errorAndException("Error response: ${error.message} (code: ${error.code})");
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
