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

/// Represents a request for OIDC authorization.
///
/// This structure contains the necessary data to initiate an OIDC authorization process
class WMTOIDCAuthorizationRequest {

  /// The Uri to initiate the authorization process. This Uri is typically opened in a browser or web view.
  final Uri authorizeUri;

  /// The identifier of the OIDC provider.
  final String providerId;

  /// A unique value used to prevent replay attacks.
  /// This value is generated for each request and must match the response from the provider.
  final String nonce;

  /// A unique value used to maintain state between the request and callback.
  /// This is useful for preventing cross-site request forgery (CSRF) attacks.
  final String state;

  /// An optional code verifier used for PKCE (Proof Key for Code Exchange) when PKCE is enabled.
  /// This value is required to complete the authorization process securely if PKCE is used.
  final String? codeVerifier;

  WMTOIDCAuthorizationRequest({
    required this.authorizeUri,
    required this.providerId,
    required this.nonce,
    required this.state,
    this.codeVerifier,
  });
}
