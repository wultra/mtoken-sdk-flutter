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

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:mtoken_sdk_flutter/mtoken_sdk_flutter.dart';

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

  setUp(() {
    channelCalls = [];
    timeSynchronized = true;
    localTimeAdjustment = 0;
    serverTime = DateTime.now().millisecondsSinceEpoch;
    synchronizeTimeFails = false;

    operations = WMTOperations(PowerAuth("proximityTestInstance"), "https://test.wultra.com/enrollment-server");

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      channelCalls.add(call.method);
      switch (call.method) {
        case "isTimeSynchronized":
          return timeSynchronized;
        case "synchronizeTime":
          if (synchronizeTimeFails) {
            throw PlatformException(code: "TIME_SYNC_FAILED", message: "Time synchronization failed");
          }
          timeSynchronized = true;
          return null;
        case "localTimeAdjustment":
          return localTimeAdjustment;
        case "currentTime":
          return serverTime;
        default:
          throw UnimplementedError("Method ${call.method} not mocked");
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  group("ensureTimeSynchronized", () {

    test("does not synchronize when time is already synchronized", () async {
      timeSynchronized = true;

      await operations.ensureTimeSynchronized();

      expect(channelCalls, contains("isTimeSynchronized"));
      expect(channelCalls, isNot(contains("synchronizeTime")));
    });

    test("synchronizes when time is not synchronized", () async {
      timeSynchronized = false;

      await operations.ensureTimeSynchronized();

      expect(channelCalls, containsAllInOrder(["isTimeSynchronized", "synchronizeTime"]));
    });

    test("throws when time synchronization fails", () async {
      timeSynchronized = false;
      synchronizeTimeFails = true;

      await expectLater(operations.ensureTimeSynchronized(), throwsA(isA<PowerAuthException>()));
    });
  });

  group("buildProximityCheckRequestData", () {

    test("builds request data with serialized otp and type", () async {
      final proximityCheck = WMTOperationProximityCheck(totp: "123456", type: WMTProximityCheckType.qrCode);

      final data = await operations.buildProximityCheckRequestData(proximityCheck);

      expect(data["otp"], "123456");
      expect(data["type"], "QR_CODE");
    });

    test("serializes deeplink type", () async {
      final proximityCheck = WMTOperationProximityCheck(totp: "654321", type: WMTProximityCheckType.deeplink);

      final data = await operations.buildProximityCheckRequestData(proximityCheck);

      expect(data["type"], "DEEPLINK");
    });

    test("adjusts timestampReceived by positive local time adjustment", () async {
      localTimeAdjustment = 5000; // device is 5 seconds behind the server
      final proximityCheck = WMTOperationProximityCheck(totp: "123456", type: WMTProximityCheckType.qrCode);

      final data = await operations.buildProximityCheckRequestData(proximityCheck);

      expect(data["timestampReceived"], proximityCheck.timestampReceived.millisecondsSinceEpoch + 5000);
    });

    test("adjusts timestampReceived by negative local time adjustment", () async {
      localTimeAdjustment = -30000; // device is 30 seconds ahead of the server
      final proximityCheck = WMTOperationProximityCheck(totp: "123456", type: WMTProximityCheckType.qrCode);

      final data = await operations.buildProximityCheckRequestData(proximityCheck);

      expect(data["timestampReceived"], proximityCheck.timestampReceived.millisecondsSinceEpoch - 30000);
    });

    test("uses server-synchronized time as timestampSent", () async {
      serverTime = 1700000000000;
      final proximityCheck = WMTOperationProximityCheck(totp: "123456", type: WMTProximityCheckType.qrCode);

      final data = await operations.buildProximityCheckRequestData(proximityCheck);

      expect(data["timestampSent"], 1700000000000);
    });
  });

  group("WMTOperationProximityCheck", () {

    test("constructor captures current time as timestampReceived", () {
      final before = DateTime.now();
      final proximityCheck = WMTOperationProximityCheck(totp: "123456", type: WMTProximityCheckType.qrCode);
      final after = DateTime.now();

      expect(proximityCheck.totp, "123456");
      expect(proximityCheck.type, WMTProximityCheckType.qrCode);
      expect(proximityCheck.timestampReceived.isBefore(before), isFalse);
      expect(proximityCheck.timestampReceived.isAfter(after), isFalse);
    });

    test("deprecated create factory ignores the provided timestampReceived", () {
      final customTimestamp = DateTime.fromMillisecondsSinceEpoch(0);
      final before = DateTime.now();
      // ignore: deprecated_member_use_from_same_package
      final proximityCheck = WMTOperationProximityCheck.create(totp: "123456", type: WMTProximityCheckType.qrCode, timestampReceived: customTimestamp);
      final after = DateTime.now();

      expect(proximityCheck.timestampReceived, isNot(customTimestamp));
      expect(proximityCheck.timestampReceived.isBefore(before), isFalse);
      expect(proximityCheck.timestampReceived.isAfter(after), isFalse);
    });

    test("deprecated withSynchronizedTime does not use the PowerAuth instance", () async {
      final before = DateTime.now();
      // ignore: deprecated_member_use_from_same_package
      final proximityCheck = await WMTOperationProximityCheck.withSynchronizedTime(totp: "123456", type: WMTProximityCheckType.deeplink, powerAuth: PowerAuth("proximityTestInstance"));
      final after = DateTime.now();

      expect(proximityCheck.totp, "123456");
      expect(proximityCheck.type, WMTProximityCheckType.deeplink);
      expect(proximityCheck.timestampReceived.isBefore(before), isFalse);
      expect(proximityCheck.timestampReceived.isAfter(after), isFalse);
      // no platform call shall be made
      expect(channelCalls, isEmpty);
    });
  });
}
