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

import '../core/exception.dart';

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

  /// Include time in the logs?
  static bool includeTime = true;

  // TODO: Make this internal!

  static void debug(String message) {
    _log(message, WMTLoggerVerbosity.debug);
  }

  static void info(String message) {
    _log(message, WMTLoggerVerbosity.info);
  }

  static void warn(String message) {
    _log(message, WMTLoggerVerbosity.warn);
  }

  static void verbose(String message) {
    _log(message, WMTLoggerVerbosity.verbose);
  }

  static void error(String message) {
    _log(message, WMTLoggerVerbosity.error);
  }

  static WMTException errorAndException(String message, { Object? additionalData }) {
    _log(message, WMTLoggerVerbosity.error);
    return WMTException(description: message, additionalData: additionalData);
  }

  static void _log(String message, WMTLoggerVerbosity logVerbosity) {
    if (verbosity.level >= logVerbosity.level) {
        // ignore: avoid_print
        print("[WMT:${logVerbosity.tag}${includeTime ? " - ${DateTime.now().toIso8601String()}" : ""}] ${message}");
    }
  }
}
