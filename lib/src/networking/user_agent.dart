import 'package:mtoken_sdk_flutter/src/utils/default_user_agent.dart';

class WMTUserAgent {

  bool _libraryDefault;
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

  // TODO: Make this internal?
  Future<String?> get() async {
    if (_custom != null) {
      return _custom!;
    }
    if (_libraryDefault) {
      return WMTDefaultUserAgent.userAgent;
    }
    return null;
  }
}