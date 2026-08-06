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

import 'package:meta/meta.dart';
import 'user_operation.dart';

typedef OperationsChange =
    ({
      List<WMTUserOperation> operations,
      List<WMTUserOperation> removed,
      List<WMTUserOperation> added,
    });

@internal
class OperationsRegister {
  final List<WMTUserOperation> _operations = [];

  OperationsChange replace(List<WMTUserOperation> operations) {
    final currentIds = _operations.map((operation) => operation.id).toSet();
    final newIds = operations.map((operation) => operation.id).toSet();
    final added =
        operations
            .where((operation) => !currentIds.contains(operation.id))
            .toList();
    final removed =
        _operations
            .where((operation) => !newIds.contains(operation.id))
            .toList();

    _operations
      ..clear()
      ..addAll(operations);
    return _change(removed, added);
  }

  OperationsChange? add(WMTUserOperation operation) {
    if (_operations.any((current) => current.id == operation.id)) return null;
    _operations.add(operation);
    return _change([], [operation]);
  }

  OperationsChange? remove(String operationId) {
    final index = _operations.indexWhere(
      (operation) => operation.id == operationId,
    );
    if (index < 0) return null;
    return _change([_operations.removeAt(index)], []);
  }

  void clear() => _operations.clear();

  OperationsChange _change(
    List<WMTUserOperation> removed,
    List<WMTUserOperation> added,
  ) => (
    operations: List.unmodifiable(_operations),
    removed: List.unmodifiable(removed),
    added: List.unmodifiable(added),
  );
}
