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
import 'dart:typed_data';

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:meta/meta.dart';
import 'user_agent.dart';
import 'response_error.dart';
import '../core/exception.dart';
import '../core/logger.dart';

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
    final paHeader = await powerAuth.authenticationHeaderForRequestWithBody(
      auth,
      "POST",
      uriId,
      Uint8List.fromList(utf8.encode(body)),
    );

    final headers = {
      paHeader.name: paHeader.value
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
      paHeader.name: paHeader.value
    };

    return await post(body, endpoindPath, headers, requestProcessor);
  }

  @internal
  Future<dynamic> post(
    String payloadSerialized,
    String endpointPath,
    Map<String, String> headers,
    WMTRequestProcessor? requestProcessor,
    { WMTE2EEConfiguration? e2ee }
  ) async {

    final client = HttpClient();
    final url = "${_baseUrl}${endpointPath}";
    PowerAuthEncryptor? encryptor;

    try {

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

      // TODO: Support other E2EE configurations
      Uint8List bodyToSend = Uint8List.fromList(utf8.encode(payloadSerialized));

      // Application-scope encryption
      if (e2ee == WMTE2EEConfiguration.applicationScope) {
        // Get encryptor
        encryptor = await powerAuth.getEncryptorForApplicationScope();

        // Encrypt plaintext payload
        final encrypted = await encryptor.encryptRequest(bodyToSend);

        // Add E2EE headers
        for (final header in encrypted.requestHeaders) {
          request.headers.set(header.name, header.value);
        }

        // HTTP body is now the encrypted request body
        bodyToSend = encrypted.requestBody;
      }

      request.add(bodyToSend);

      if (requestProcessor != null) {
        requestProcessor(request.headers);
      }

      Log.info(" -> OUTGOING POST ${url}");
      Log.verbose(() => _getHeadersString(request.headers));
      Log.debug(utf8.decode(bodyToSend, allowMalformed: true));

      final response = await request.close();
      final responseBytes = Uint8List.fromList(await response.expand((chunk) => chunk).toList());
      final clearResponseBytes = encryptor != null && response.statusCode == 200
          ? await encryptor.decryptResponse(responseBytes)
          : responseBytes;
      final responseBody = utf8.decode(clearResponseBytes);

      Log.info(" <-- INCOMMING POST ${url}, status code ${response.statusCode}");
      Log.verbose(() => _getHeadersString(response.headers));
      Log.debug(responseBody);

      Map<String, dynamic> data;

      data = jsonDecode(responseBody) as Map<String, dynamic>;

      final responseObject = data["responseObject"];

      if (data["status"] != "OK") {
        final error = WMTResponseError.fromJson(responseObject as Map<String, dynamic>);
        throw WMTException(description: "Error response retrieved", responseError: error);
      }

      return responseObject;

    } catch (e) {
      // Log the error and rethrow it
      Log.error("Error during POST request to ${url}: ${e.toString()}");
      rethrow;
    } finally {
      client.close();
      await encryptor?.release();
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

enum WMTE2EEConfiguration {
  notEncrypted,
  applicationScope,
  // activationScope, // can be added later
}
