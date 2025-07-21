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
import '../core/logger.dart';

class Log {
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
    if (WMTLogger.verbosity.level >= logVerbosity.level) {
        // ignore: avoid_print
        print("[WMT:${logVerbosity.tag}${WMTLogger.includeTime ? " - ${DateTime.now().toIso8601String()}" : ""}] ${message}");
    }
  }
}