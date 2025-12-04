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
import 'dart:typed_data';

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:mtoken_sdk_flutter/src/oidc/pkce_codes.dart';
import 'package:mtoken_sdk_flutter/mtoken_sdk_flutter.dart';

import '../core/logger.dart';

/// Utility class for OIDC helper methods.
class WMTOIDCUtils {
  static const int _minLength = 32; // 32 bytes ≈ 43 Base64uri chars
  static const int _maxLength = 96; // 96 bytes ≈ 128 Base64uri chars

  /// Creates PKCE codes using PowerAuthCryptoUtils for randomness and SHA-256.
  ///
  /// - [dataLength] is the number of *bytes* to generate before Base64 encoding.
  ///   If outside allowed bounds, `_minLength` is used.
  ///
  /// Throws [WMTException] with description containing `oidc_codeChallengeGenerationFailed`.
  static Future<WMTPKCECodes> createPKCE({required int dataLength}) async {
    final length = (dataLength > _minLength && dataLength < _maxLength) ? dataLength : _minLength;

    try {
      // 1) Generate a random codeVerifier as Base64uri.
      final codeVerifier = await getRandomBase64UrlSafe(length);

      // 2) SHA-256(verifier), then Base64uri.
      final verifierBytes = Uint8List.fromList(ascii.encode(codeVerifier));
      final digest = await PowerAuthCryptoUtils.hashSha256(verifierBytes);
      final codeChallenge = _toBase64UrlSafe(digest);

      return WMTPKCECodes(
        codeVerifier: codeVerifier,
        codeChallenge: codeChallenge,
        codeMethod: "S256",
      );
    } on PowerAuthException catch (e) {
      Log.error("OIDC: PKCE generation failed (PowerAuth error): $e");
      throw WMTException(
        description: "[${WMTOIDCError.codeChallengeGenerationFailed.code}] Failed to generate PKCE codes",
        originalException: e,
      );
    } catch (e) {
      Log.error("OIDC: PKCE generation failed (unexpected): $e");
      throw WMTException(
        description: "[${WMTOIDCError.codeChallengeGenerationFailed.code}] Unexpected error during PKCE generation",
        originalException: e,
      );
    }
  }

  /// Generates a random Base64 uri-safe string (without padding) using
  /// PowerAuthCryptoUtils.randomBytes.
  static Future<String> getRandomBase64UrlSafe(int dataLength) async {
    try {
      final Uint8List bytes = await PowerAuthCryptoUtils.randomBytes(dataLength);
      return _toBase64UrlSafe(bytes);
    } on PowerAuthException catch (e) {
      Log.error("OIDC: Random bytes generation failed (PowerAuth error): $e");
      throw WMTException(
        description: "[${WMTOIDCError.randomBytesFailed.code}] Failed to generate random bytes",
        originalException: e,
      );
    } catch (e) {
      Log.error("OIDC: Random bytes generation failed (unexpected): $e");
      throw WMTException(
        description: "[${WMTOIDCError.randomBytesFailed.code}] Unexpected error during random bytes generation",
        originalException: e,
      );
    }
  }

  /// Creates an OpenID Connect authorization uri.
  ///
  /// Throws [WMTException] with description containing `oidc_authorizationUriCreationFailed`
  /// when the uri cannot be created.
  static Uri createAuthorizationUri({
    required WMTOIDCConfig config,
    required String nonce,
    required String state,
    WMTPKCECodes? pkceCodes,
  }) {
    try {
      final baseUri = Uri.parse(config.authorizeUri);

      final params = <String, String>{
        "client_id": config.clientId,
        "redirect_uri": config.redirectUri,
        "scope": config.scopes,
        "state": state,
        "nonce": nonce,
        "response_type": "code",
      };

      if (pkceCodes != null) {
        params["code_challenge"] = pkceCodes.codeChallenge;
        params["code_challenge_method"] = pkceCodes.codeMethod;
      }

      final uri = baseUri.replace(queryParameters: params);
      Log.debug("OIDC: Successfully created authorizationUri");
      return uri;
    } catch (e) {
      Log.warn("OIDC: Failed to create authorization uri: $e");
      throw WMTException(
        description: "[${WMTOIDCError.authorizationUriCreationFailed.code}] Failed to create authorization uri",
        originalException: e,
      );
    }
  }

  /// Processes a deeplink uri to validate state and extract OIDC activation attributes.
  ///
  /// Throws [WMTException] with description containing `oidc_invalidDeeplink` when invalid.
  static WMTOIDCPowerAuthActivationAttributes processWebCallback({
    required Uri uri,
    required WMTOIDCAuthorizationRequest authData,
  }) {
    final query = uri.queryParameters;
    if (query.isEmpty) {
      Log.error("OIDC: Invalid callback uri: scheme=${uri.scheme}, host=${uri.host}, path=${uri.path}");
      throw WMTException(
        description: "[${WMTOIDCError.invalidDeeplink.code}] Invalid OIDC callback uri",
      );
    }

    final code = query["code"];
    if (code == null) {
      Log.error("OIDC: Authorization code missing in callback: scheme=${uri.scheme}, host=${uri.host}, path=${uri.path}");
      throw WMTException(
        description: "[${WMTOIDCError.invalidDeeplink.code}] Missing authorization code in callback",
      );
    }

    final state = query["state"];
    if (state == null) {
      Log.error("OIDC: State parameter missing in callback: scheme=${uri.scheme}, host=${uri.host}, path=${uri.path}");
      throw WMTException(
        description: "[${WMTOIDCError.invalidDeeplink.code}] Missing state in callback",
      );
    }

    if (state != authData.state) {
      Log.error("OIDC: State mismatch in callback. Expected state does not match received state. scheme=${uri.scheme}, host=${uri.host}, path=${uri.path}");
      throw WMTException(
        description: "[${WMTOIDCError.invalidDeeplink.code}] State mismatch in callback",
      );
    }

    return WMTOIDCPowerAuthActivationAttributes(
      providerId: authData.providerId,
      code: code,
      nonce: authData.nonce,
      codeVerifier: authData.codeVerifier,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Base64 uri-safe encoding without padding
  /// Dart's base64Url.encode already produces uri-safe strings (+ -> -, / -> _), 
  /// so we just need to remove the padding characters.
  static String _toBase64UrlSafe(Uint8List bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}