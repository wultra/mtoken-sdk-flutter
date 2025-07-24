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

import 'dart:convert';

/// Decodes a Base64 string that may not be padded correctly.
String decodeBase64Safe(String base64Str) {
  // Add padding if necessary
  int padding = base64Str.length % 4;
  if (padding > 0) {
    base64Str += '=' * (4 - padding);
  }

  return utf8.decode(base64.decode(base64Str));
}
