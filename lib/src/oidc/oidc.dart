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

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:mtoken_sdk_flutter/mtoken_sdk_flutter.dart';
import 'package:mtoken_sdk_flutter/src/core/logger.dart';
import 'package:mtoken_sdk_flutter/src/networking/networking.dart';

class WMTOIDC extends WMTNetworking {

  /// Constructor that initializes the oidc networking layer.
  /// 
  /// Params:
  /// - [powerAuth] is the PowerAuth instance used for signing requests.
  /// - [baseUrl] is the base URL of the Wultra Mobile Token API (usually ending with /enrollment-server).
  WMTOIDC(PowerAuth powerAuth, String baseUrl) : super(powerAuth, baseUrl, "WMTOIDC");

  /// Retrieves configuration based on predefined [providerId].
  ///
  /// Encrypted with the ECIES application scope.
  ///
  /// [providerId] is the identification of the configuration record, used as a key for the configuration.
  /// [requestProcessor] is an optional request processor for customizing the HTTP request.
  ///
  /// Returns a [WMTOIDCConfig] containing the OIDC provider configuration.
  Future<WMTOIDCConfig> getConfig(String providerId, { WMTRequestProcessor? requestProcessor }) async {
    final payload = jsonEncode({"providerId": providerId});
    
    final responseObject = await post(
      payload,
      "/api/config/oidc",
      {},
      requestProcessor,
      e2ee: WMTE2EEConfiguration.applicationScope
    );

    return WMTOIDCConfig.fromJson(responseObject as Map<String, dynamic>);
  }

  /// Prepares authorization data required to start an OIDC login flow.
  ///
  /// This method:
  ///  - Generates a `state` and `nonce` value for request validation.
  ///  - Generates PKCE values when the provider configuration enables PKCE.
  ///  - Builds the full authorization URL that must be opened in a browser or web view.
  ///
  /// The returned [WMTOIDCAuthorizationRequest] contains everything needed to:
  ///  1. Redirect the user to the provider’s login page (`authorizeUrl`)
  ///  2. Later validate the final redirect URL from the provider
  ///
  /// After the provider finishes authentication, the resulting redirect/deeplink URL
  /// can be passed to [WMTOIDCUtils.processWebCallback], which validates the state,
  /// extracts authorization parameters, and produces [WMTOIDCPowerAuthActivationAttributes]
  /// suitable for `PowerAuth.createOidcActivation()`.
  ///
  /// Throws:
  ///  - [WMTException] if PKCE generation, random value generation, or URL
  ///    construction fails.
  Future<WMTOIDCAuthorizationRequest> prepareAuthorizationData(WMTOIDCConfig config) async {

    // Using 32 bytes for PKCE code verifiers aligns with RFC 7636 (https://datatracker.ietf.org/doc/html/rfc7636).
    // For nonce and state, OpenID Connect does not specify a strict length, but 32 bytes ensures strong randomness to prevent replay and CSRF attacks.
    final pkceCodes = config.pkceEnabled ? await WMTOIDCUtils.createPKCE(dataLength: 32) : null;
    final nonce = await WMTOIDCUtils.getRandomBase64UrlSafe(32);
    final state = await WMTOIDCUtils.getRandomBase64UrlSafe(32);

    final authorizeUri = WMTOIDCUtils.createAuthorizationUri(config: config, nonce: nonce, state: state, pkceCodes: pkceCodes);
    return WMTOIDCAuthorizationRequest(
      authorizeUri: authorizeUri,
      providerId: config.providerId,
      nonce: nonce,
      state: state,
      codeVerifier: pkceCodes?.codeVerifier,
    );
  }
}

/// Adds a helper for creating activation via OIDC attributes.
extension PowerAuthOidcActivation on PowerAuth {

  /// Creates PowerAuth activation based on the data in the
  /// [WMTOIDCPowerAuthActivationAttributes] object.
  ///
  /// - [attributes]: Contains providerId, code, nonce and optional codeVerifier
  ///   obtained from your OIDC flow.
  /// - [activationName]: Activation/device name.
  ///
  /// On success returns the result from [createActivation].
  /// On failure throws [WMTException] with `originalException` set.
  Future<PowerAuthCreateActivationResult> createOidcActivation(
    WMTOIDCPowerAuthActivationAttributes attributes, {
    required String activationName,
  }) async {
    try {
      final activation = PowerAuthActivation.fromOIDC(
        oidcParameters: PowerAuthOIDCParameters(
          providerId: attributes.providerId,
          code: attributes.code,
          nonce: attributes.nonce,
          codeVerifier: attributes.codeVerifier,
        ),
        name: activationName,
      );

      final result = await createActivation(activation);
      return result;
    } catch (e) {
      Log.error("OIDC: Activation failed with error: $e");

      throw WMTException(
        description: "[${WMTOIDCError.activationFailed}] OIDC Activation Failed",
        originalException: e,
      );
    }
  }
}
