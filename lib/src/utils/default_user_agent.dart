import '../core/version.dart';

class WMTDefaultUserAgent {
  
  static String get userAgent {
    final product = "MobileTokenFlutter";
    final sdkVer = wmtSdkVersion;
    final envInfo = EnvironmenInfo();
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
class EnvironmenInfo {
  final String applicationVersion = "1.0.0";
  final String applicationIdentifier = "com.example.mtoken";
  final String deviceManufacturer = "ExampleManufacturer";
  final String deviceId = "ExampleDeviceId123";
  final String systemName = "ExampleOS";
  final String systemVersion = "1.2.3";
}