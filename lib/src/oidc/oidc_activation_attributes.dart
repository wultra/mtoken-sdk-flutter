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


/// Represents the attributes required to complete an OIDC-based PowerAuth activation.
class WMTOIDCPowerAuthActivationAttributes {

  /// The identifier of the OIDC provider
  final String providerId;

  /// The authorization code returned by the OIDC authentication flow.
  final String code;

  /// A unique nonce value used for security validation.
  final String nonce;
  
  /// (Optional) The code verifier used in the PKCE flow.
  final String? codeVerifier;

  WMTOIDCPowerAuthActivationAttributes({
    required this.providerId,
    required this.code,
    required this.nonce,
    this.codeVerifier,
  });
}