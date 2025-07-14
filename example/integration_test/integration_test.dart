import 'dart:io';

import 'package:example/test_utils/integration_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtoken_sdk_flutter/mtoken_sdk_flutter.dart';

void main() {

  group("operation tests", () {

    @protected late IntegrationHelper helper;
    @protected late PowerAuth sdk;
    @protected late WultraMobileToken wmt;
    @protected late ActivationCredentials credentials;

    setUpAll(() async {
      WMTLogger.verbosity = WMTLoggerVerbosity.debug;
      credentials = ActivationCredentials();
    });

    setUp(() async {
      sdk = PowerAuth(IntegrationHelper.randomString(30));
      helper = IntegrationHelper(sdk);
      await helper.configure();
      wmt = sdk.createMobileToken();
      await helper.prepareActiveActivation(await credentials.validPasswordObject());
      expect(await sdk.hasValidActivation(), isTrue);
    });

    tearDown(() async {
      await helper.removeRegistration();
      await sdk.removeActivationLocal();
      expect(await sdk.hasValidActivation(), isFalse);
    });

    test("testList", () async {
      await helper.createOperation();
      final operations = await wmt.operations.getOperations();
      expect(operations.length, 1);
    });

    test("testDetail", () async {
      final op = await helper.createOperation();
      final detail = await wmt.operations.getDetail(op.operationId);
      expect(detail.id, op.operationId);
      expect(detail.name, op.operationType);
    });

    test("testClaim", () async {

    });

    test("testAuthorize", () async {
      final op = await helper.createOperation();
      final detail = await wmt.operations.getDetail(op.operationId);

      // try to authorize with invalid password
      try {
        await wmt.operations.auhtorize(detail, PowerAuthAuthentication.password(await credentials.invalidPasswordObject()));
        fail("Authorization should fail with invalid password");
      } catch (e) {
        // TODO: better exception
        expect(e, isA<Exception>());
      }

      // authorize with correct password
      await wmt.operations.auhtorize(detail, PowerAuthAuthentication.password(await credentials.validPasswordObject()));
    });

    test("testReject", () async {
      final op = await helper.createOperation();

      // try to reject with invalid password
      try {
        await wmt.operations.reject(op.operationId, WMTRejectionReason.unknown());
      } catch (e) {
        fail("Rejection failed : ${e}");
      }
    });

    test("testMobileTokenData", () async {
      
      final op = await helper.createOperation();
      final detail = await wmt.operations.getDetail(op.operationId);

      expect(detail.mobileTokenData, isNull);

      detail.mobileTokenData = {
        "test1": 1,
        "test2": 2.3,
        "test3": "string",
        "test4": {
          "nested": true
        }
      };

      expect(detail.mobileTokenData, isNotNull);

      // authorize with correct password
      await wmt.operations.auhtorize(detail, PowerAuthAuthentication.password(await credentials.validPasswordObject()));

      final opAfterApproval = await helper.getOperation(detail.id);
      final mobileTokenData = opAfterApproval.additionalData["mobileTokenData"];
      expect(mobileTokenData, isNotNull);
      expect(mobileTokenData["test1"], 1);
      expect(mobileTokenData["test2"], 2.3);
      expect(mobileTokenData["test3"], "string");
      expect(mobileTokenData["test4"]["nested"], isTrue);
    });
  });
}