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
import 'package:meta/meta.dart';
import 'package:mtoken_sdk_flutter/src/networking/networking.dart';

/// Push networking layer for Wultra Mobile Token API.
final class WMTPush extends WMTNetworking {

  /// Constructor that initializes the push networking layer.
  /// 
  /// Params:
  /// - [powerAuth] is the PowerAuth instance used for signing requests.
  /// - [baseUrl] is the base URL of the Wultra Mobile Token API (usually ending with /enrollment-server).
  WMTPush(super.powerAuth, super.baseUrl);

  /// Registers the PowerAuth activation for push notifications on the PowerAuth backend.
  /// 
  /// To provide the push token, use the [WMTPushPlatform] class to create a platform-specific push token.
  /// 
  /// Params:
  ///  - [data] Push platform and token.
  ///  - [requestProcessor] You may modify the request headers via this processor.
  ///
  /// ----
  ///
  /// For example, to register an FCM (Firebase Cloud Messaging) token, you can use:
  /// ```dart
  /// final pushData = WMTPushPlatform.fcm("your_fcm_token");
  /// await wmt.push.register(pushData);
  /// ```
  /// ----
  /// 
  /// If you are using an older version of the Wultra Mobile Token API (1.9 or earlier), you may need to use the legacy format:
  /// ```dart
  /// final pushData = WMTPushPlatform.fcm("your_fcm_token").supportLegacyServer();
  /// await wmt.push.register(pushData);
  /// ```
  Future<void> register(WMTPushPlatform data, { WMTRequestProcessor? requestProcessor }) async {
    await postSignedWithToken(
      { "requestObject": data.toRequestObject() },
      PowerAuthAuthentication.possession(),
      "/api/push/device/register/token",
      "possession_universal",
      requestProcessor: requestProcessor,
    );
  }
}

/// Represents a push platform and its token for Wultra Mobile Token API.
final class WMTPushPlatform {

  final String _token;
  final _PushPlatform _platform;
  final WMTPushApnsEnvironment? _apnsEnvironment;
  bool _useLegacyFormat = false;

  WMTPushPlatform._(this._token, this._platform, { WMTPushApnsEnvironment? environment })
      : _apnsEnvironment = environment;

  /// Create a PushData instance for Apple Push Notification Service (APNs).
  ///
  /// Params:
  /// - [token] device token received from APNs. Format of the token is usually a hexadecimal string.
  /// - [environment] optional environment for APNs.
  /// The environment can be either [WMTPushApnsEnvironment.development] or [WMTPushApnsEnvironment.production].
  /// If not set, then the environment is not specified and the server will use the configured environment.
  factory WMTPushPlatform.apns(String token, { WMTPushApnsEnvironment? environment }) {
    return WMTPushPlatform._(token, _PushPlatform.apns, environment: environment);
  }

  /// Create a PushData instance for Firebase Cloud Messaging (FCM).
  ///
  /// Params:
  /// - [token] device token received from FCM.
  factory WMTPushPlatform.fcm(String token) {
    return WMTPushPlatform._(token, _PushPlatform.fcm);
  }

  /// Create a PushData instance for Huawei Mobile Services (HMS).
  ///
  /// Params:
  /// - [token] device token received from HMS.
  factory WMTPushPlatform.hms(String token) {
    return WMTPushPlatform._(token, _PushPlatform.hms);
  }

  /// If your server is running an older version of the Wultra Mobile Token API (1.9 or earlier), you may need to use the legacy format.
  WMTPushPlatform supportLegacyServer() {
    _useLegacyFormat = true;
    return this;
  }

  @internal
  Map<String, String> toRequestObject() {
    final object = { "token": _token };
    switch (_platform) {
      case _PushPlatform.apns:
        object["platform"] = _useLegacyFormat ? "ios" : "apns";
        if (_apnsEnvironment != null && !_useLegacyFormat) {
          object["environment"] = _apnsEnvironment.value;
        }
      case _PushPlatform.fcm:
        object["platform"] = _useLegacyFormat ? "android" : "fcm";
      case _PushPlatform.hms:
        object["platform"] = _useLegacyFormat ? "huawei" : "hms";
    }
    return object;
  }
}

/// Environment for Apple Push Notification Service (APNs).
enum WMTPushApnsEnvironment {
  development("development"),
  production("production");

  @internal
  final String value;
  const WMTPushApnsEnvironment(this.value);
}

enum _PushPlatform {
  apns,
  fcm,
  hms
}