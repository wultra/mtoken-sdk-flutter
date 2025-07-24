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

import '../core/version.dart';

class WMTDefaultUserAgent {
  
  static String get userAgent {
    final product = "MobileTokenFlutter";
    final sdkVer = wmtSdkVersion;
    final envInfo = EnvironmentInfo();
    final appVer = envInfo.applicationVersion;
    final appId = envInfo.applicationIdentifier;
    final maker = envInfo.deviceManufacturer;
    final model = envInfo.deviceId;
    final os = envInfo.systemName;
    final osVer = envInfo.systemVersion;
    final userAgent = "${product}/${sdkVer} ${appId}/${appVer} (${maker}; ${os}/${osVer}; ${model})";
    return userAgent;
  }
}

// TODO: replace with actual environment info retrieval from the PowerAuth SDK (https://github.com/wultra/flutter-powerauth-mobile-sdk/issues/45)
class EnvironmentInfo {
  final String applicationVersion = "1.0.0";
  final String applicationIdentifier = "com.example.mtoken";
  final String deviceManufacturer = "ExampleManufacturer";
  final String deviceId = "ExampleDeviceId123";
  final String systemName = "ExampleOS";
  final String systemVersion = "1.2.3";
}