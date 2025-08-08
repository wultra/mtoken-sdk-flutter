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

import '../networking/known_rest_api_error.dart';

/// Error object when error on the server happens.
class WMTResponseError {
  /// Error code, which is one of the [WMTKnownRestApiError] values.
  WMTKnownRestApiError code;
  /// Error message, which is usually localized message for the user.
  String message;

  WMTResponseError(this.code, this.message);

  factory WMTResponseError.fromJson(Map<String, dynamic> json) {
    final code = WMTKnownRestApiError.fromCode(json['code'] as String);
    return WMTResponseError(code, json['message'] as String);
  }
}