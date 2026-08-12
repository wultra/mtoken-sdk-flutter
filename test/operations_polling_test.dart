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

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtoken_sdk_flutter/mtoken_sdk_flutter.dart';
import 'package:mtoken_sdk_flutter/src/networking/networking.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _TestOperations operations;
  late _OperationsListener listener;

  setUp(() {
    operations = _TestOperations();
    listener = _OperationsListener();
    operations.listener = listener;
  });

  tearDown(() => operations.stopPollingOperations());

  test("shares an operation list request and reports its state", () async {
    final response = Completer<dynamic>();
    operations.tokenHandler = (_) => response.future;

    final first = operations.getOperations();
    final second = operations.getOperations();

    expect(identical(first, second), isTrue);
    expect(operations.isLoadingOperations, isTrue);
    expect(operations.tokenRequests, 1);
    expect(listener.loading, [true]);

    response.complete([_operationJson("1")]);
    expect((await first).map((operation) => operation.id), ["1"]);
    await second;

    expect(operations.isLoadingOperations, isFalse);
    expect(listener.loading, [true, false]);
    expect(listener.changes.single.added.map((operation) => operation.id), [
      "1",
    ]);
    expect(operations.lastFetchResult?.isSuccess, isTrue);
  });

  test("reports added, removed and failed operations", () async {
    operations.tokenHandler =
        (_) async => [_operationJson("1"), _operationJson("2")];
    await operations.getOperations();

    operations.tokenHandler =
        (_) async => [_operationJson("2"), _operationJson("3")];
    await operations.getOperations();

    final change = listener.changes.last;
    expect(change.operations.map((operation) => operation.id), ["2", "3"]);
    expect(change.removed.map((operation) => operation.id), ["1"]);
    expect(change.added.map((operation) => operation.id), ["3"]);

    operations.tokenHandler =
        (_) async => [
          {..._operationJson("3"), "name": "updated"},
          _operationJson("2"),
        ];
    await operations.getOperations();
    expect(listener.changes.last.operations.map((operation) => operation.id), [
      "2",
      "3",
    ]);
    expect(listener.changes.last.operations.last.name, "test");
    expect(listener.changes.last.removed, isEmpty);
    expect(listener.changes.last.added, isEmpty);

    final error = StateError("failed");
    operations.tokenHandler = (_) => Future.error(error);
    await expectLater(operations.getOperations(), throwsA(same(error)));
    expect(listener.errors, [error]);
    expect(operations.lastFetchResult?.isFailure, isTrue);
    expect(operations.isLoadingOperations, isFalse);
  });

  test("listener failures do not change operation results", () async {
    operations.listener = _ThrowingOperationsListener();
    operations.tokenHandler =
        (endpoint) async =>
            endpoint.endsWith("claim")
                ? _operationJson("2")
                : [_operationJson("1")];

    final fetched = await operations.getOperations();
    expect(fetched.map((operation) => operation.id), ["1"]);
    expect(operations.lastFetchResult?.isSuccess, isTrue);
    expect(operations.isLoadingOperations, isFalse);

    final claimed = await operations.claim("2");
    expect(claimed.id, "2");

    final requestError = StateError("request failed");
    operations.tokenHandler = (_) => Future.error(requestError);
    await expectLater(operations.getOperations(), throwsA(same(requestError)));
    expect(operations.lastFetchResult?.error, same(requestError));
    expect(operations.isLoadingOperations, isFalse);
  });

  test("updates registered operations after successful mutations", () async {
    operations.tokenHandler =
        (endpoint) async =>
            endpoint.endsWith("claim")
                ? _operationJson("3")
                : [_operationJson("1"), _operationJson("2")];
    final current = await operations.getOperations();
    await operations.claim("3");

    operations.signedHandler = (_) async => {};
    await operations.authorize(
      current[0],
      PowerAuthAuthentication.possession(),
    );
    await operations.reject("2", WMTRejectionReason.unknown());

    expect(listener.changes[1].added.map((operation) => operation.id), ["3"]);
    expect(listener.changes[2].removed.map((operation) => operation.id), ["1"]);
    expect(listener.changes[3].removed.map((operation) => operation.id), ["2"]);

    operations.signedHandler = (_) => Future.error(StateError("failed"));
    await expectLater(
      operations.reject("3", WMTRejectionReason.unknown()),
      throwsStateError,
    );
    expect(listener.changes, hasLength(4));
  });

  test("does not publish a list response made stale by a mutation", () async {
    operations.tokenHandler = (_) async => [_operationJson("1")];
    await operations.getOperations();

    final staleResponse = Completer<dynamic>();
    operations.tokenHandler = (_) => staleResponse.future;
    final listRequest = operations.getOperations();

    operations.signedHandler = (_) async => {};
    await operations.reject("1", WMTRejectionReason.unknown());

    staleResponse.complete([_operationJson("1")]);

    expect((await listRequest).map((operation) => operation.id), ["1"]);
    expect(operations.tokenRequests, 2);
    expect(listener.changes.last.operations, isEmpty);
    expect(listener.changes.skip(2).expand((change) => change.added), isEmpty);
  });

  test("preserves existing operation instances during refresh", () async {
    operations.tokenHandler = (_) async => [_operationJson("1")];
    final original = (await operations.getOperations()).single;
    final proximityCheck = WMTOperationProximityCheck(
      totp: "12345678",
      type: WMTProximityCheckType.qrCode,
    );
    final mobileTokenData = <String, Object>{"custom": true};
    original.proximityCheck = proximityCheck;
    original.mobileTokenData = mobileTokenData;

    operations.tokenHandler =
        (_) async => [{..._operationJson("1"), "name": "updated"}];
    final refreshed = (await operations.getOperations()).single;

    final registered = listener.changes.last.operations.single;
    expect(registered, same(original));
    expect(registered.proximityCheck, same(proximityCheck));
    expect(registered.mobileTokenData, same(mobileTokenData));
    expect(registered.name, "test");
    expect(refreshed, isNot(same(original)));
    expect(refreshed.name, "updated");
  });

  test("does not publish an error from a stale list request", () async {
    operations.tokenHandler = (_) async => [_operationJson("1")];
    await operations.getOperations();
    final successfulResult = operations.lastFetchResult;

    final staleResponse = Completer<dynamic>();
    operations.tokenHandler = (_) => staleResponse.future;
    final listRequest = operations.getOperations();

    operations.signedHandler = (_) async => {};
    await operations.reject("1", WMTRejectionReason.unknown());

    final staleError = StateError("stale failure");
    staleResponse.completeError(staleError);

    await expectLater(listRequest, throwsA(same(staleError)));
    expect(operations.lastFetchResult, same(successfulResult));
    expect(listener.errors, isEmpty);
  });

  test("starts immediately, ignores duplicate starts and stops", () async {
    operations.tokenHandler = (_) async => <dynamic>[];
    void requestProcessor(_) {}

    operations.startPollingOperations(requestProcessor: requestProcessor);
    expect(operations.isPollingOperations, isTrue);
    expect(operations.tokenRequests, 1);
    expect(operations.lastRequestProcessor, same(requestProcessor));

    operations.startPollingOperations(interval: const Duration(seconds: 10));
    expect(operations.tokenRequests, 1);

    operations.stopPollingOperations();
    expect(operations.isPollingOperations, isFalse);
  });

  test("delays polling and enforces the minimum interval", () async {
    operations.tokenHandler = (_) async => <dynamic>[];
    operations.startPollingOperations(
      interval: const Duration(milliseconds: 10),
      delayStart: true,
    );

    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(operations.tokenRequests, 0);
  });
}

class _TestOperations extends WMTOperations {
  _TestOperations()
    : super(PowerAuth("operations-test"), "https://test.wultra.com");

  Future<dynamic> Function(String endpoint)? tokenHandler;
  Future<dynamic> Function(String endpoint)? signedHandler;
  int tokenRequests = 0;
  WMTRequestProcessor? lastRequestProcessor;

  @override
  Future<dynamic> postSignedWithToken(
    Object requestData,
    PowerAuthAuthentication auth,
    String endpointPath,
    String tokenName, {
    WMTRequestProcessor? requestProcessor,
  }) {
    tokenRequests++;
    lastRequestProcessor = requestProcessor;
    return tokenHandler!(endpointPath);
  }

  @override
  Future<dynamic> postSigned(
    Object requestData,
    PowerAuthAuthentication auth,
    String endpointPath,
    String uriId, {
    WMTRequestProcessor? requestProcessor,
  }) {
    return signedHandler!(endpointPath);
  }
}

class _OperationsListener implements WMTOperationsListener {
  final loading = <bool>[];
  final errors = <Object>[];
  final changes =
      <
        ({
          List<WMTUserOperation> operations,
          List<WMTUserOperation> removed,
          List<WMTUserOperation> added,
        })
      >[];

  @override
  void operationsChanged(
    List<WMTUserOperation> operations,
    List<WMTUserOperation> removed,
    List<WMTUserOperation> added,
  ) {
    changes.add((operations: operations, removed: removed, added: added));
  }

  @override
  void operationsFailed(Object error) => errors.add(error);

  @override
  void operationsLoading(bool value) => loading.add(value);
}

class _ThrowingOperationsListener implements WMTOperationsListener {
  @override
  void operationsChanged(
    List<WMTUserOperation> operations,
    List<WMTUserOperation> removed,
    List<WMTUserOperation> added,
  ) => throw StateError("operationsChanged failed");

  @override
  void operationsFailed(Object error) =>
      throw StateError("operationsFailed failed");

  @override
  void operationsLoading(bool loading) =>
      throw StateError("operationsLoading failed");
}

Map<String, dynamic> _operationJson(String id) => {
  "id": id,
  "data": "data",
  "status": "PENDING",
  "name": "test",
  "operationCreated": "2026-01-01T00:00:00Z",
  "operationExpires": "2026-01-01T00:05:00Z",
  "allowedSignatureType": {
    "type": "1FA",
    "variants": ["possession"],
  },
  "formData": {"title": "Test", "message": "", "attributes": []},
};
