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

import 'user_operation.dart';

/// Listener for operation list loading and changes.
abstract class WMTOperationsListener {
  void operationsChanged(List<WMTUserOperation> operations, List<WMTUserOperation> removed, List<WMTUserOperation> added);
  void operationsLoading(bool loading);
  void operationsFailed(Object error);
}

/// Last result of an operation list request.
class WMTGetOperationsResult {
  final List<WMTUserOperation>? operations;
  final Object? error;

  const WMTGetOperationsResult.success(List<WMTUserOperation> this.operations) : error = null;
  const WMTGetOperationsResult.failure(Object this.error) : operations = null;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}
