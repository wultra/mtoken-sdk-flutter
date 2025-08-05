import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import '../core/version.dart';

class WMTUserAgent {

  bool _libraryDefault;
  // ignore: unused_field
  bool _systemDefault;
  String? _custom;

  WMTUserAgent._(this._libraryDefault, this._systemDefault, this._custom);

  factory WMTUserAgent.libraryDefault() {
    return WMTUserAgent._(true, false, null);
  }

  factory WMTUserAgent.systemDefault() {
    return WMTUserAgent._(false, true, null);
  }

  factory WMTUserAgent.custom(String userAgent) {
    return WMTUserAgent._(false, false, userAgent);
  }

  /// Gets the user agent string.
  /// 
  /// Returns null if the user agent is set to system default.
  Future<String?> get() async {
    if (_custom != null) {
      return _custom!;
    }
    if (_libraryDefault) {
      return await _defaultUserAgent();
    }
    return null;
  }

  String get description {
    if (_custom != null) {
      return "WMTUserAgent(custom: $_custom)";
    }
    if (_libraryDefault) {
      return "WMTUserAgent(libraryDefault)";
    }
    return "WMTUserAgent(systemDefault)";
  }

  Future<String> _defaultUserAgent() async {
    final product = "MobileTokenFlutter";
    final sdkVer = wmtSdkVersion;
    final envInfo = await PowerAuthUtils.getEnvironmentInfo();
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