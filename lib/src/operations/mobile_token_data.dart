/*
 * Copyright 2026 Wultra s.r.o.
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

import 'dart:async';

/// Interface for structured records that contribute to mobile token data.
///
/// Implement this to create reusable, self-contained data records
/// that can be added to [WMTMobileTokenDataBuilder].
abstract class WMTMobileTokenDataRecord {
  /// Stable key under which this record is stored in the mobile token data map.
  String get key;

  /// Builds the value representation of this record.
  ///
  /// The returned value must be JSON-serializable (primitives, maps, lists).
  /// May return a [Future] for async implementations.
  FutureOr<dynamic> build();
}

/// Builder for composing structured mobile token data for operation authorization.
///
/// Use this to assemble the `mobileTokenData` payload that is sent along with
/// the operation authorize request. Supports both generic key-value entries
/// and structured [WMTMobileTokenDataRecord] instances.
///
/// Example usage:
/// ```dart
/// final builder = WMTMobileTokenDataBuilder();
/// builder.put('customKey', 'customValue');
/// await builder.putRecord(recorder);
///
/// operation.mobileTokenData = builder.build();
/// ```
class WMTMobileTokenDataBuilder {
  final Map<String, dynamic> _data = {};

  /// Creates a builder with optional initial entries.
  WMTMobileTokenDataBuilder([Map<String, dynamic>? initialData]) {
    if (initialData != null) {
      _data.addAll(initialData);
    }
  }

  /// Adds or replaces a generic key-value entry.
  ///
  /// The [value] must be JSON-serializable.
  /// Returns this builder for chaining.
  WMTMobileTokenDataBuilder put(String key, dynamic value) {
    _data[key] = value;
    return this;
  }

  /// Adds or replaces a structured [record] by its key.
  ///
  /// The record's [WMTMobileTokenDataRecord.build] result is stored under [WMTMobileTokenDataRecord.key].
  /// Returns this builder for chaining.
  Future<WMTMobileTokenDataBuilder> putRecord(WMTMobileTokenDataRecord record) async {
    _data[record.key] = await record.build();
    return this;
  }

  /// Removes an entry by [key].
  ///
  /// Returns `true` if the key was found and removed.
  bool remove(String key) {
    if (_data.containsKey(key)) {
      _data.remove(key);
      return true;
    }
    return false;
  }

  /// Removes all entries.
  ///
  /// Returns this builder for chaining.
  WMTMobileTokenDataBuilder clear() {
    _data.clear();
    return this;
  }

  /// Builds an immutable snapshot of the collected data.
  Map<String, dynamic> build() {
    return Map.unmodifiable(Map<String, dynamic>.from(_data));
  }
}
