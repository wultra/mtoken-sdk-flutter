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


/// Represents PKCE (Proof Key for Code Exchange) codes used in OAuth 2.0 and OpenID Connect flows
/// to enhance the security of authorization code exchanges.
///
/// The PKCE mechanism mitigates the risk of authorization code interception attacks by requiring
/// the client to prove possession of a secure random secret (code verifier) during the exchange.
class WMTPKCECodes {
  
  /// A high-entropy cryptographic random value, as described in [Section 4.1]
  /// (https://datatracker.ietf.org/doc/html/rfc7636#section-4.1) of the PKCE standard.
  final String codeVerifier;
  
  /// A transformation of the codeVerifier, as defined in [Section 4.2]
  /// (https://datatracker.ietf.org/doc/html/rfc7636#section-4.2) of the PKCE standard.
  final String codeChallenge;

  /// Conveniently stored hash method which was used for codeChallenge creation
  final String codeMethod;

  WMTPKCECodes({
    required this.codeVerifier,
    required this.codeChallenge,
    required this.codeMethod,
  });
}