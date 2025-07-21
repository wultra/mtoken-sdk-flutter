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
import 'utils/log_utils.dart';
import 'networking/user_agent.dart';
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

  // Private constructor to enforce the use of the factory method.
  WultraMobileToken._(this.operations, this.push, this.inbox);

  /// 
  /// [powerAuth] PowerAuth instance. Needs to be activated when calling any method of this class - othewise error will be thrown.
  /// 
  /// [acceptLanguage] Optionally sets the accept language for the outgoing requests headers for `operations`, `push` and `inbox` objects.
  ///                  The default value is "en".
  ///                  The value can be further modified in the each service object individualy.
  ///                  Standard RFC "Accept-Language" https://tools.ietf.org/html/rfc7231#section-5.3.5
  ///                  Response texts are based on this setting. For example when "de" is set, server
  ///                  will return operation texts in german (if available).
  /// 
  /// [userAgent] Optionally sets the User agent that will be used in a HTTP hader. 
  ///             Note that user-agent can be overriden by request processor in each API call.
  ///             The default value is [WMTUserAgent.libraryDefault], which is a user agent that contains the library name and version. 
  /// 
  /// Can throw when a null or invalid `baseEndpointUrl` is set in the `PowerAuth` instance.
  factory WultraMobileToken.create({required PowerAuth powerAuth, String? acceptLanguage, WMTUserAgent? userAgent}) {

    final baseURL = powerAuth.configuration?.baseEndpointUrl;

    if (baseURL == null || baseURL.isEmpty) {
      throw ArgumentError("PowerAuth configuration must contain a valid base endpoint URL.");
    }

    final operations = WMTOperations(powerAuth, baseURL);
    final push = WMTPush(powerAuth, baseURL);
    final inbox = WMTInbox(powerAuth, baseURL);

    // set default accept language and user agent
    final lang = acceptLanguage ?? "en";
    operations.acceptLanguage = lang;
    push.acceptLanguage = lang;
    inbox.acceptLanguage = lang;

    final agent = userAgent ?? WMTUserAgent.libraryDefault();
    operations.userAgent = agent;
    push.userAgent = agent;
    inbox.userAgent = agent;

    Log.debug("Mobile Token object created with:");
    Log.debug(" - baseURL: $baseURL");
    Log.debug(" - acceptLanguage: ${acceptLanguage}");
    Log.debug(" - userAgent: ${agent.description}");

    return WultraMobileToken._(operations, push, inbox);
  }

  /// Sets accept language for the outgoing requests headers for [operations], [push] and [inbox] objects.
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
      Log.info("Accept language set to ${lang} for all services.");
  }
}

extension PowerAuthExtension on PowerAuth {

  /// Creates a [WultraMobileToken] instance using the current PowerAuth instance.
  /// 
  /// URL from the `PowerAuthSDK` instance is used for services.
  /// 
  /// [acceptLanguage] Optionally sets the accept language for the outgoing requests headers for `operations`, `push` and `inbox` objects.
  ///                  The default value is "en".
  ///                  The value can be further modified in the each service object individualy.
  ///                  Standard RFC "Accept-Language" https://tools.ietf.org/html/rfc7231#section-5.3.5
  ///                  Response texts are based on this setting. For example when "de" is set, server
  ///                  will return operation texts in german (if available).
  /// 
  /// [userAgent] Optionally sets the User agent that will be used in a HTTP hader.
  ///             Note that user-agent can be overriden by request processor in each API call.
  ///             The default value is [WMTUserAgent.libraryDefault], which is a user agent that contains the library name and version.
  WultraMobileToken createMobileToken({String? acceptLanguage, WMTUserAgent? userAgent}) {
    return WultraMobileToken.create(powerAuth: this, acceptLanguage: acceptLanguage, userAgent: userAgent);
  }
}