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

/// Typed error codes used in the OIDC (OpenID Connect) flow.
class WMTOIDCError {
  
  /// Raw string error code, e.g. "oidc_invalidDeeplink".
  final String code;

  const WMTOIDCError._(this.code);

  /// Error when generating random bytes for cryptographic purposes failed.
  static const randomBytesFailed = WMTOIDCError._("oidc_randomBytesFailed");

  /// Error when PKCE code challenge generation failed.
  static const codeChallengeGenerationFailed = WMTOIDCError._("oidc_codeChallengeGenerationFailed");

  /// Error when deeplink cannot be parsed or handled.
  static const invalidDeeplink = WMTOIDCError._("oidc_invalidDeeplink");

  /// Error when authorization URL creation failed.
  static const authorizationUriCreationFailed = WMTOIDCError._("oidc_authorizationUriCreationFailed");

  /// Error when PowerAuth activation via OIDC failed.
  static const activationFailed = WMTOIDCError._("oidc_activationFailed");
}