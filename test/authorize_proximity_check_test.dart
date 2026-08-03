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

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:mtoken_sdk_flutter/mtoken_sdk_flutter.dart';

/// Minimal online operation for testing the authorize flow.
class _TestOperation implements WMTOnlineOperation {
  @override
  String get id => "test-operation-id";

  @override
  String get data => "A1*A100CZK*ICZ2730300000001165254011";

  @override
  WMTOperationProximityCheck? proximityCheck;

  @override
  Object? mobileTokenData;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('powerauth_plugin');

  late WMTOperations operations;
  late List<String> channelCalls;

  // Mocked time synchronization state of the PowerAuth plugin.
  late bool timeSynchronized;
  late int localTimeAdjustment;
  late int serverTime;
  late bool synchronizeTimeFails;

  // The proximityCheck request data captured from the signed authorize request body.
  Map<String, dynamic>? capturedProximityRequest;

  setUp(() {
    channelCalls = [];
    timeSynchronized = true;
    localTimeAdjustment = 0;
    serverTime = DateTime.now().millisecondsSinceEpoch + 60000; 
    synchronizeTimeFails = false;
    capturedProximityRequest = null;

    operations = WMTOperations(
      PowerAuth("proximityTestInstance"),
      "https://test.wultra.com/enrollment-server",
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          channelCalls.add(call.method);
          switch (call.method) {
            case "isTimeSynchronized":
              return timeSynchronized;
            case "synchronizeTime":
              if (synchronizeTimeFails) {
                throw PlatformException(
                  code: "TIME_SYNC_FAILED",
                  message: "Time synchronization failed",
                );
              }
              timeSynchronized = true;
              return null;
            case "localTimeAdjustment":
              return localTimeAdjustment;
            case "currentTime":
              return serverTime;
            case "requestSignature":
              // Capture the request body that would be signed and sent to the server,
              // then abort so no real HTTP request is made.
              final body =
                  jsonDecode(call.arguments["body"] as String)
                      as Map<String, dynamic>;
              capturedProximityRequest =
                  (body["requestObject"]
                          as Map<String, dynamic>)["proximityCheck"]
                      as Map<String, dynamic>?;
              throw PlatformException(
                code: "TEST_ABORT",
                message: "Aborting before network call",
              );
            default:
              throw UnimplementedError("Method ${call.method} not mocked");
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  /// Authorizes the operation, expecting the flow to reach the (mocked) signing step
  /// where the request body is captured and the flow is aborted before any network call.
  /// Returns the captured proximityCheck request data.
  Future<Map<String, dynamic>?> authorizeAndCaptureRequest(
    WMTOnlineOperation operation,
  ) async {
    await expectLater(
      operations.authorize(operation, PowerAuthAuthentication.possession()),
      throwsA(anything),
    );
    expect(channelCalls, contains("requestSignature"));
    return capturedProximityRequest;
  }

  group("authorize time synchronization", () {
    test("does not synchronize when time is already synchronized", () async {
      timeSynchronized = true;
      final operation =
          _TestOperation()
            ..proximityCheck = WMTOperationProximityCheck(
              totp: "123456",
              type: WMTProximityCheckType.qrCode,
            );

      await authorizeAndCaptureRequest(operation);

      expect(channelCalls, contains("isTimeSynchronized"));
      expect(channelCalls, isNot(contains("synchronizeTime")));
    });

    test("synchronizes when time is not synchronized", () async {
      timeSynchronized = false;
      final operation =
          _TestOperation()
            ..proximityCheck = WMTOperationProximityCheck(
              totp: "123456",
              type: WMTProximityCheckType.qrCode,
            );

      await authorizeAndCaptureRequest(operation);

      expect(
        channelCalls,
        containsAllInOrder(["isTimeSynchronized", "synchronizeTime"]),
      );
    });

    test("throws when time synchronization fails", () async {
      timeSynchronized = false;
      synchronizeTimeFails = true;
      final operation =
          _TestOperation()
            ..proximityCheck = WMTOperationProximityCheck(
              totp: "123456",
              type: WMTProximityCheckType.qrCode,
            );

      await expectLater(
        operations.authorize(operation, PowerAuthAuthentication.possession()),
        throwsA(isA<PowerAuthException>()),
      );
      // the flow must fail before signing the request
      expect(channelCalls, isNot(contains("requestSignature")));
    });

    test(
      "does not touch time synchronization without a proximity check",
      () async {
        final operation = _TestOperation();

        await authorizeAndCaptureRequest(operation);

        expect(channelCalls, isNot(contains("isTimeSynchronized")));
        expect(channelCalls, isNot(contains("synchronizeTime")));
        expect(capturedProximityRequest, isNull);
      },
    );
  });

  group("authorize proximity check request data", () {
    test("builds request data with serialized otp and type", () async {
      final operation =
          _TestOperation()
            ..proximityCheck = WMTOperationProximityCheck(
              totp: "123456",
              type: WMTProximityCheckType.qrCode,
            );

      final data = await authorizeAndCaptureRequest(operation);

      expect(data?["otp"], "123456");
      expect(data?["type"], "QR_CODE");
    });

    test("serializes deeplink type", () async {
      final operation =
          _TestOperation()
            ..proximityCheck = WMTOperationProximityCheck(
              totp: "654321",
              type: WMTProximityCheckType.deeplink,
            );

      final data = await authorizeAndCaptureRequest(operation);

      expect(data?["type"], "DEEPLINK");
    });

    test(
      "adjusts timestampReceived by positive local time adjustment",
      () async {
        localTimeAdjustment = 5000; // device is 5 seconds behind the server
        final proximityCheck = WMTOperationProximityCheck(
          totp: "123456",
          type: WMTProximityCheckType.qrCode,
        );
        final operation = _TestOperation()..proximityCheck = proximityCheck;

        final data = await authorizeAndCaptureRequest(operation);

        expect(
          data?["timestampReceived"],
          proximityCheck.timestampReceived.millisecondsSinceEpoch + 5000,
        );
      },
    );

    test(
      "adjusts timestampReceived by negative local time adjustment",
      () async {
        localTimeAdjustment =
            -30000; // device is 30 seconds ahead of the server
        final proximityCheck = WMTOperationProximityCheck(
          totp: "123456",
          type: WMTProximityCheckType.qrCode,
        );
        final operation = _TestOperation()..proximityCheck = proximityCheck;

        final data = await authorizeAndCaptureRequest(operation);

        expect(
          data?["timestampReceived"],
          proximityCheck.timestampReceived.millisecondsSinceEpoch - 30000,
        );
      },
    );

    test("uses server-synchronized time as timestampSent", () async {
      // Use a fixed past server time to produce a deterministic, recognizable value.
      const expectedServerTime = 1700000000000; // ~2023-11-14

      // Create the proximity check first to capture timestampReceived (= device's DateTime.now()).
      final proximityCheck = WMTOperationProximityCheck(
        totp: "123456",
        type: WMTProximityCheckType.qrCode,
      );
      final receivedAt = proximityCheck.timestampReceived.millisecondsSinceEpoch;

      localTimeAdjustment = expectedServerTime - receivedAt;
      serverTime = expectedServerTime;

      final operation = _TestOperation()..proximityCheck = proximityCheck;
      final data = await authorizeAndCaptureRequest(operation);

      expect(data?["timestampSent"], expectedServerTime);
    });

    test(
      "throws WMTException when device time changes after receive",
      () async {
        final proximityCheck = WMTOperationProximityCheck(
          totp: "123456",
          type: WMTProximityCheckType.qrCode,
        );
        final receivedAt =
            proximityCheck.timestampReceived.millisecondsSinceEpoch;
        final operation = _TestOperation()..proximityCheck = proximityCheck;

        // Simulate the device clock moving 5 minutes behind after the QR code
        // was received but before authorize builds the request.
        localTimeAdjustment = 5 * 60 * 1000;
        serverTime = receivedAt + 1000;

        await expectLater(
          operations.authorize(operation, PowerAuthAuthentication.possession()),
          throwsA(isA<WMTException>()),
        );
        // The SDK should reject before reaching the signing step.
        expect(channelCalls, isNot(contains("requestSignature")));
      },
    );
  });

  group("WMTOperationProximityCheck", () {
    test("constructor captures current time as timestampReceived", () {
      final before = DateTime.now();
      final proximityCheck = WMTOperationProximityCheck(
        totp: "123456",
        type: WMTProximityCheckType.qrCode,
      );
      final after = DateTime.now();

      expect(proximityCheck.totp, "123456");
      expect(proximityCheck.type, WMTProximityCheckType.qrCode);
      expect(proximityCheck.timestampReceived.isBefore(before), isFalse);
      expect(proximityCheck.timestampReceived.isAfter(after), isFalse);
    });

    test(
      "deprecated create factory ignores the provided timestampReceived",
      () {
        final customTimestamp = DateTime.fromMillisecondsSinceEpoch(0);
        final before = DateTime.now();
        // ignore: deprecated_member_use_from_same_package
        final proximityCheck = WMTOperationProximityCheck.create(
          totp: "123456",
          type: WMTProximityCheckType.qrCode,
          timestampReceived: customTimestamp,
        );
        final after = DateTime.now();

        expect(proximityCheck.timestampReceived, isNot(customTimestamp));
        expect(proximityCheck.timestampReceived.isBefore(before), isFalse);
        expect(proximityCheck.timestampReceived.isAfter(after), isFalse);
      },
    );

    test(
      "deprecated withSynchronizedTime does not use the PowerAuth instance",
      () async {
        final before = DateTime.now();
        // ignore: deprecated_member_use_from_same_package
        final proximityCheck =
            await WMTOperationProximityCheck.withSynchronizedTime(
              totp: "123456",
              type: WMTProximityCheckType.deeplink,
              powerAuth: PowerAuth("proximityTestInstance"),
            );
        final after = DateTime.now();

        expect(proximityCheck.totp, "123456");
        expect(proximityCheck.type, WMTProximityCheckType.deeplink);
        expect(proximityCheck.timestampReceived.isBefore(before), isFalse);
        expect(proximityCheck.timestampReceived.isAfter(after), isFalse);
        // no platform call shall be made
        expect(channelCalls, isEmpty);
      },
    );
  });
}
