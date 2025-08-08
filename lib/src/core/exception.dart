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

import '../networking/response_error.dart';

/// Possible logic errors during the API calls.
class WMTException {

  /// Description of the Exception.
  String description;

  /// If the exception is caused by an original exception, this field contains it.
  Object? originalException;

  /// Response error if the exception is caused by a server error.
  WMTResponseError? responseError;

  WMTException({ required this.description, this.originalException, this.responseError });

  @override
  String toString() {
    final buffer = StringBuffer("WMTException: ${description}");
    if (originalException != null) {
      buffer.write(" (original exception: ${originalException})");
    }
    if (responseError != null) {
      buffer.write(" (server response error: message ${responseError!.message}, code: ${responseError!.code})");
    }
    return buffer.toString();
  }
}