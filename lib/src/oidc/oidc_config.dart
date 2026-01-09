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

/// Config data contains essential OIDC configuration values for authentication.
class WMTOIDCConfig {
  
  /// Provider's identifier.
  final String providerId;

  /// Identification of the OAuth 2.0 client, to form the URL for authorize request.
  final String clientId;

  /// OAuth 2.0 scopes, to form the URL for authorize request.
  final String scopes;

  /// OAuth 2.0 authorize URI, to form the URL for authorize request.
  final String authorizeUri;

  /// OAuth 2.0 redirect URI, the endpoint to which the OAuth 2.0 server can send responses.
  final String redirectUri;

  /// If PKCE (Proof Key for Code Exchange) extension should be used.
  final bool pkceEnabled;

  const WMTOIDCConfig({
    required this.providerId,
    required this.clientId,
    required this.scopes,
    required this.authorizeUri,
    required this.redirectUri,
    required this.pkceEnabled,
  });

  /// Creates a [WMTOIDCConfig] from a JSON.
  factory WMTOIDCConfig.fromJson(Map<String, dynamic> json) {
    return WMTOIDCConfig(
      providerId: json['providerId'] as String,
      clientId: json['clientId'] as String,
      scopes: json['scopes'] as String,
      authorizeUri: json['authorizeUri'] as String,
      redirectUri: json['redirectUri'] as String,
      pkceEnabled: json['pkceEnabled'] as bool,
    );
  }
}
