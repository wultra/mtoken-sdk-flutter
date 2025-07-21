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

import 'operation_proximity_check.dart';

/// An abstract class that defines minimum data needed for calculating the operation signature
/// and sending it to confirmation endpoint.
abstract class WMTOnlineOperation {
  
  /// Unique operation identifier. 
  String get id;

  /// Actual data that will be signed.
  /// 
  /// This shouldn't be visible to the user.
  String get data;

  /// Additional information with proximity check data 
  abstract WMTOperationProximityCheck? proximityCheck;

  /// Additional mobile token data for authorization (available with PowerAuth server 1.10+) 
  abstract Object? mobileTokenData; // TODO: add test for serialization
}