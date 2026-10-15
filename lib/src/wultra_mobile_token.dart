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

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:mtoken_sdk_flutter/src/oidc/oidc.dart';
import 'core/logger.dart';
import 'configuration.dart';
import 'operations/operations.dart';
import 'push/push.dart';
import 'inbox/inbox.dart';

/// MobileToken class exposes APIs that enable:
///  - Fetching, authorizing or rejecting basic
///  - operations created in the PowerAuth stack.
///  - Push notifications enrollment.
///  - Inbox message management.
class WultraMobileToken {
  /// Operations networking layer for Wultra Mobile Token API.
  final WMTOperations operations;

  /// Push networking layer for Wultra Mobile Token API.
  final WMTPush push;

  /// Inbox networking layer for Wultra Mobile Token API.
  final WMTInbox inbox;

  /// OIDC networking layer for Wultra Mobile Token API.
  final WMTOIDC oidc;

  /// Immutable configuration used when creating all networking services.
  final WMTConfiguration configuration;

  // Private constructor to enforce the use of the factory method.
  WultraMobileToken._(
    this.operations,
    this.push,
    this.inbox,
    this.oidc,
    this.configuration,
  );

  /// Creates all networking services using [configuration].
  ///
  /// [powerAuth] must have a valid base endpoint URL and be activated before
  /// calling services that require an activation.
  ///
  /// The configuration defaults to English and the SDK user agent, with no
  /// request interceptors. Its interceptor list is shared by every service.
  static Future<WultraMobileToken> create({
    required PowerAuth powerAuth,
    WMTConfiguration? configuration,
  }) async {
    final powerAuthConfiguration = await powerAuth.configuration;
    final baseURL = powerAuthConfiguration.baseEndpointUrl;
    if (baseURL.isEmpty) {
      throw ArgumentError(
        "PowerAuth configuration must contain a valid base endpoint URL.",
      );
    }

    final config = configuration ?? WMTConfiguration();
    final operations = WMTOperations(powerAuth, baseURL, configuration: config);
    final push = WMTPush(powerAuth, baseURL, configuration: config);
    final inbox = WMTInbox(powerAuth, baseURL, configuration: config);
    final oidc = WMTOIDC(powerAuth, baseURL, configuration: config);

    Log.verbose("Mobile Token object created with:");
    Log.verbose(" - baseURL: $baseURL");
    Log.verbose(" - acceptLanguage: ${config.acceptLanguage}");
    Log.verbose(" - userAgent: ${config.userAgent.description}");

    return WultraMobileToken._(operations, push, inbox, oidc, config);
  }

  /// Sets accept language for the outgoing requests headers for [operations], [push], [inbox], and [oidc] objects.
  ///
  /// The value can be further modified in the each object individualy.
  ///
  /// Default value is "en".
  ///
  /// Standard RFC "Accept-Language" https://tools.ietf.org/html/rfc7231#section-5.3.5
  /// Response texts are based on this setting. For example when "de" is set, server
  /// will return operation texts in german (if available).
  setAcceptLanguage(String lang) {
    operations.acceptLanguage = lang;
    push.acceptLanguage = lang;
    inbox.acceptLanguage = lang;
    oidc.acceptLanguage = lang;
    Log.info("Accept language set to ${lang} for all services.");
  }
}

extension PowerAuthExtension on PowerAuth {
  /// Creates a Mobile Token instance using this PowerAuth instance and its URL.
  ///
  /// [configuration] sets the initial language, user agent, and immutable list
  /// of request interceptors shared by all networking services.
  Future<WultraMobileToken> createMobileToken({
    WMTConfiguration? configuration,
  }) {
    return WultraMobileToken.create(
      powerAuth: this,
      configuration: configuration,
    );
  }
}
