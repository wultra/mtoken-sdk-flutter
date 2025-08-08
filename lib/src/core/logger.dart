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

import 'package:meta/meta.dart';
import '../networking/response_error.dart';
import 'exception.dart';

/// How much should Mobile Token library log into the console.
enum WMTLoggerVerbosity {
  /// No logs will be printed.
  none(0, "NON"),
  /// Only errors will be printed into the console.
  error(1, "ERR"),
  /// Warnings and errors will be printed into the console.
  warn(2, "WRN"),
  /// Info logs, warnings and errors will be printed into the console.
  info(3, "INF"),
  /// All but debug messages will be printed into the console.
  verbose(4, "VBS"),
  /// All logs are on.
  debug(5, "DBG");

  final int level;
  final String tag;
  const WMTLoggerVerbosity(this.level, this.tag);
}

/// Mobile Token logging utility.
class WMTLogger {

  /// Which level of logs (and lower) should be logged into the console. Default value is `warn`.
  static WMTLoggerVerbosity verbosity = WMTLoggerVerbosity.warn;

  /// Print time in the console logs?
  /// Default value is `true`.
  static bool printTime = true;

  /// Sets the log listener that is called when a message is logged.
  /// 
  /// Can be used when you want to capture logs in your application, for example, to send them to a server or save them to a file.
  /// 
  /// Params:
  /// - [listener] is the listener that is called when a message is logged.
  /// - [followVerbosity] Whether to follow the verbosity level of logging. Default value is `true`.
  ///                     When set to true, then (for example) if `error` is selected as a `verbosity`, error messages will be reported.
  ///                     When set to false, all methods might be called no matter the selected `verbosity`.
  static void setLogListener({WMTLogListener? listener, bool followVerbosity = true}) {
    if (listener == null) {
      Log._logListener = null;
    } else {
      Log._logListener = _ClosureLogListener(listener, followVerbosity);
    }
  }
}

/// Log listener that is called when a message is logged.
typedef WMTLogListener = void Function(String message, WMTLoggerVerbosity verbosity);

/// Internal utility class for logging messages into the console.
@internal class Log {

  static _ClosureLogListener? _logListener;

  static void debug(dynamic object) {
    _log(object, WMTLoggerVerbosity.debug);
  }

  static void info(dynamic object) {
    _log(object, WMTLoggerVerbosity.info);
  }

  static void warn(dynamic object) {
    _log(object, WMTLoggerVerbosity.warn);
  }

  static void verbose(dynamic object) {
    _log(object, WMTLoggerVerbosity.verbose);
  }

  static void error(dynamic object) {
    _log(object, WMTLoggerVerbosity.error);
  }

  static WMTException errorAndException(String message, { WMTResponseError? serverError, Object? originalException}) {
    _log(() => message, WMTLoggerVerbosity.error);
    return WMTException(description: message, originalException: originalException, responseError: serverError);
  }

  static void _log(dynamic object, WMTLoggerVerbosity logVerbosity) {
    final isVerbosityAllowed = WMTLogger.verbosity.level >= logVerbosity.level;
    // log only if the verbosity level is allowed or log listener does not follow the verbosity level
    if (_logListener?._followVerboseLevel == false || isVerbosityAllowed) {
      
      final String message;
      if (object is String Function()) {
        message = object.call();
      } else if (object is String) {
        message = object;
      } else {
        message = object.toString();
      }

      // print to the console only if the verbosity level is allowed
      if (isVerbosityAllowed) {
        // ignore: avoid_print
        print("[WMT:${logVerbosity.tag}${WMTLogger.printTime ? " - ${DateTime.now().toIso8601String()}" : ""}] ${message}");
      }
      // call the log listener if set
      _logListener?.call(message, logVerbosity);
    }
  }
}

class _ClosureLogListener {
  final WMTLogListener _listener;
  final bool _followVerboseLevel;

  _ClosureLogListener(this._listener, this._followVerboseLevel);

  void call(String message, WMTLoggerVerbosity verbosity) {
    _listener(message, verbosity);
  }
}
