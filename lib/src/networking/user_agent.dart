import '../utils/default_user_agent.dart';

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
      return WMTDefaultUserAgent.userAgent;
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
}