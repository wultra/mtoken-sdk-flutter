import 'dart:async';

import 'package:example/test_utils/integration_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtoken_sdk_flutter/mtoken_sdk_flutter.dart';

void main() {

  group("integration tests", () {

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

    test("testOperationPolling", () async {
      final completed = Completer<void>();
      var loadingCount = 0;
      wmt.operations.listener = _PollingListener(
        onLoading: (loading) {
          if (loading) loadingCount++;
          if (!loading && loadingCount == 2 && !completed.isCompleted) {
            completed.complete();
          }
        },
        onError: (error) {
          if (!completed.isCompleted) completed.completeError(error);
        },
      );

      wmt.operations.startPollingOperations(interval: const Duration(seconds: 5));
      try {
        await completed.future.timeout(const Duration(seconds: 15));
      } finally {
        wmt.operations.stopPollingOperations();
      }
      expect(loadingCount, 2);
      expect(wmt.operations.isPollingOperations, isFalse);
    });

    test("testOperationPollingDetectsAddedAndRemovedOperations", () async {
      final operation = await helper.createOperation();
      final added = Completer<void>();
      final removed = Completer<void>();
      List<WMTUserOperation>? latestOperations;

      wmt.operations.listener = _PollingListener(
        onChanged: (operations, removedOperations, addedOperations) {
          latestOperations = operations;
          if (!added.isCompleted && addedOperations.any((item) => item.id == operation.operationId)) {
            added.complete();
          }
          if (!removed.isCompleted && removedOperations.any((item) => item.id == operation.operationId)) {
            removed.complete();
          }
        },
        onError: (error) {
          if (!added.isCompleted) added.completeError(error);
          if (!removed.isCompleted) removed.completeError(error);
        },
      );

      wmt.operations.startPollingOperations(interval: const Duration(seconds: 5));
      try {
        await added.future.timeout(const Duration(seconds: 10));
        expect(latestOperations?.map((item) => item.id), contains(operation.operationId));

        await helper.cancelOperation(operation.operationId, "CANCELED_BY_TEST");
        await removed.future.timeout(const Duration(seconds: 10));
        expect(latestOperations?.map((item) => item.id), isNot(contains(operation.operationId)));
      } finally {
        wmt.operations.stopPollingOperations();
      }
    });

    test("testOperationPollingDelayedStartAndDuplicateStart", () async {
      final loadingEvents = <bool>[];
      final requestFinished = Completer<void>();

      wmt.operations.listener = _PollingListener(
        onLoading: (loading) {
          loadingEvents.add(loading);
          if (!loading && !requestFinished.isCompleted) requestFinished.complete();
        },
        onError: (error) {
          if (!requestFinished.isCompleted) requestFinished.completeError(error);
        },
      );

      wmt.operations.startPollingOperations(
        interval: const Duration(seconds: 5),
        delayStart: true,
      );
      wmt.operations.startPollingOperations();
      try {
        await Future<void>.delayed(const Duration(seconds: 1));
        expect(loadingEvents, isEmpty);
        expect(wmt.operations.isLoadingOperations, isFalse);

        await requestFinished.future.timeout(const Duration(seconds: 7));
        expect(loadingEvents, [true, false]);
        expect(wmt.operations.lastFetchResult?.isSuccess, isTrue);
      } finally {
        wmt.operations.stopPollingOperations();
      }
    });

    test("testDisposeDoesNotRestoreStateFromInFlightPollingRequest", () async {
      await helper.createOperation();

      wmt.operations.startPollingOperations();
      expect(wmt.operations.isLoadingOperations, isTrue);

      wmt.dispose();
      expect(wmt.operations.isPollingOperations, isFalse);
      expect(wmt.operations.lastFetchResult, isNull);

      await (() async {
        while (wmt.operations.isLoadingOperations) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      })().timeout(const Duration(seconds: 10));

      expect(wmt.operations.lastFetchResult, isNull);
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
        await wmt.operations.authorize(detail, await credentials.invalidKnowledge());
        fail("Authorization should fail with invalid password");
      } on WMTException catch (e) {
        expect(e.responseError?.code, WMTKnownRestApiError.authenticationFailure);
      } catch (e) {
        fail("Wrong exception type: ${e}");
      }

      // authorize with correct password
      await wmt.operations.authorize(detail, await credentials.knowledge());
    });

    test("testReject", () async {
      final op = await helper.createOperation();

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
      await wmt.operations.authorize(detail, await credentials.knowledge());

      final opAfterApproval = await helper.getOperation(detail.id);
      final mobileTokenData = opAfterApproval.additionalData["mobileTokenData"];
      expect(mobileTokenData, isNotNull);
      expect(mobileTokenData["test1"], 1);
      expect(mobileTokenData["test2"], 2.3);
      expect(mobileTokenData["test3"], "string");
      expect(mobileTokenData["test4"]["nested"], isTrue);
    });

    test("testHistory", () async {
      // cerate 2 operations in history
      final op1 = await helper.createOperation();
      final op2 = await helper.createOperation();

      final detailOp1 = await wmt.operations.getDetail(op1.operationId);

      // authorize with correct password
      await wmt.operations.authorize(detailOp1, await credentials.knowledge());

      final history = await wmt.operations.getHistory(await credentials.knowledge());
      expect(history.length, 2);
      
      final historyOp1 = history.firstWhere((element) => element.id == op1.operationId);
      final historyOp2 = history.firstWhere((element) => element.id == op2.operationId);

      expect(historyOp1.id, op1.operationId);
      expect(historyOp2.id, op2.operationId);
      expect(historyOp1.status, WMTUserOperationStatus.approved);
      expect(historyOp2.status, WMTUserOperationStatus.pending);
    });

    test("testQROperation", () async {

      // create regular operation
      final op = await helper.createOperation();

      // get QR data for the operation
      final qrData = await helper.getQROperation(op.operationId);

      // parse the QR data
      final qrOperation = WMTQROperation.fromQRString(qrData.operationQrCodeData);

      // verify the parsed data
      final verified = await sdk.verifyServerSignedData(qrOperation.signedData, qrOperation.signature.signatureString, qrOperation.signature.signingKey == WMTSigningKey.master);
      expect(verified, isTrue);

      // get the OTP via the offline signing
      final otp = await wmt.operations.authorizeOffline(qrOperation, await credentials.knowledge());

      final verifiedResult = await helper.verifyQROperation(op.operationId, qrData, otp);

      expect(verifiedResult.otpValid, isTrue);
    });

    test("testDetail", () async {
      final op = await helper.createOperation();

      // get detail of the operation
      final detail = await wmt.operations.getDetail(op.operationId);

      // verify the detail
      expect(detail.id, op.operationId);
      expect(detail.name, op.operationType);
      expect(detail.status, WMTUserOperationStatus.pending);
    });

    test("testClaimWithTOTP", () async {
      final op = await helper.createOperation(anonymous: true, proximityCheckEnabled: true);

      // claim the operation
      final claimed = await wmt.operations.claim(op.operationId);

      expect(claimed.ui?.preApprovalScreens?.first.type, "QR_SCAN");

      final totp = (await helper.getOperation(op.operationId)).proximityOtp;
      expect(totp, isNotNull);

      claimed.proximityCheck = WMTOperationProximityCheck(totp: totp ?? "", type: WMTProximityCheckType.qrCode);

      await wmt.operations.authorize(claimed, await credentials.knowledge());
    });

    test("testProximityAuthorizeSynchronizesTimeWhenNotSynchronized", () async {
      final op = await helper.createOperation(anonymous: true, proximityCheckEnabled: true);

      // claim the operation and get its TOTP
      final claimed = await wmt.operations.claim(op.operationId);
      final totp = (await helper.getOperation(op.operationId)).proximityOtp;
      expect(totp, isNotNull);

      claimed.proximityCheck = WMTOperationProximityCheck(totp: totp ?? "", type: WMTProximityCheckType.qrCode);

      // reset the time synchronization right before authorizing
      await sdk.timeSynchronizationService.resetTimeSynchronization();
      expect(await sdk.timeSynchronizationService.isTimeSynchronized(), isFalse);

      // the SDK must synchronize the time automatically during authorize
      await wmt.operations.authorize(claimed, await credentials.knowledge());

      // time must be synchronized after the authorization
      expect(await sdk.timeSynchronizationService.isTimeSynchronized(), isTrue);

      // verify the operation was approved on the server
      expect((await helper.getOperation(op.operationId)).status, "APPROVED");
    });

    test("testProximityAuthorizeWithAlreadySynchronizedTime", () async {
      final op = await helper.createOperation(anonymous: true, proximityCheckEnabled: true);

      // claim the operation and get its TOTP
      final claimed = await wmt.operations.claim(op.operationId);
      final totp = (await helper.getOperation(op.operationId)).proximityOtp;
      expect(totp, isNotNull);

      claimed.proximityCheck = WMTOperationProximityCheck(totp: totp ?? "", type: WMTProximityCheckType.qrCode);

      // synchronize the time upfront
      await sdk.timeSynchronizationService.synchronizeTime();
      expect(await sdk.timeSynchronizationService.isTimeSynchronized(), isTrue);

      await wmt.operations.authorize(claimed, await credentials.knowledge());

      // verify the operation was approved on the server
      expect((await helper.getOperation(op.operationId)).status, "APPROVED");
    });

    test("testProximityAuthorizeIgnoresCustomTimestamp", () async {
      final op = await helper.createOperation(anonymous: true, proximityCheckEnabled: true);

      // claim the operation and get its TOTP
      final claimed = await wmt.operations.claim(op.operationId);
      final totp = (await helper.getOperation(op.operationId)).proximityOtp;
      expect(totp, isNotNull);

      // the deliberately wrong timestamp must be ignored by the SDK - it uses (server-adjusted) current time instead
      // ignore: deprecated_member_use
      claimed.proximityCheck = WMTOperationProximityCheck.create(totp: totp ?? "", type: WMTProximityCheckType.qrCode, timestampReceived: DateTime.fromMillisecondsSinceEpoch(0));

      await wmt.operations.authorize(claimed, await credentials.knowledge());

      // verify the operation was approved on the server
      expect((await helper.getOperation(op.operationId)).status, "APPROVED");
    });

    test("testClaimWithoutTOTP", () async {
      final op = await helper.createOperation(anonymous: true, proximityCheckEnabled: false);

      // claim the operation
      final claimed = await wmt.operations.claim(op.operationId);

      final totp = (await helper.getOperation(op.operationId)).proximityOtp;
      expect(totp, isNull);

      await wmt.operations.authorize(claimed, await credentials.knowledge());
    });

    test("cancelWithReason", () async {

      final op = await helper.createOperation();
      const reason = "PREARRANGED_REASON";

      // cancel the operation with a reason
      await helper.cancelOperation(op.operationId, reason);

      // verify the operation is canceled
      final history = await wmt.operations.getHistory(await credentials.knowledge());
      final opRecord = history.firstWhere((element) => element.id == op.operationId);
      expect(opRecord.status, WMTUserOperationStatus.canceled);
      expect(opRecord.statusReason, reason);
    });

    test("testUserAgent", () async {

      late WultraMobileToken tempMtoken;
      const expectedDefaultUserAgentProductName = "MobileTokenFlutter";
      const testUserAgent = "test-agent";
      final envInfo = await PowerAuthUtils.getEnvironmentInfo();

      // Test default behavior (libraryDefault)

      tempMtoken = sdk.createMobileToken();

      await tempMtoken.operations.getOperations(requestProcessor: (headers) {
        final userAgent = headers.value("user-agent")!;
        expect(userAgent.startsWith(expectedDefaultUserAgentProductName), isTrue);
        expect(userAgent.contains(envInfo.systemVersion), isTrue);
        expect(userAgent.contains(envInfo.systemName), isTrue);
        expect(userAgent.contains(envInfo.deviceId), isTrue);
        expect(userAgent.contains(envInfo.deviceManufacturer), isTrue);
        expect(userAgent.contains(envInfo.applicationIdentifier!), isTrue);
        expect(userAgent.contains(envInfo.applicationVersion!), isTrue);
      });

      // Test custom user agent
      tempMtoken = sdk.createMobileToken(userAgent: WMTUserAgent.custom(testUserAgent));

      await tempMtoken.inbox.getMessageList(0, 50, false, requestProcessor: (headers) {
        expect(headers.value("user-agent"), testUserAgent);
      });

      // Test system default

      tempMtoken = sdk.createMobileToken(userAgent: WMTUserAgent.systemDefault());

      await tempMtoken.push.register(WMTPushPlatform.fcm("test"), requestProcessor: (headers) {
        expect(headers.value("user-agent")?.startsWith("Dart"), isTrue); // default user agent is something like "Dart/2.14 (dart:io)"
      });
    });

    test("testAcceptLanguage", () async {
      const en = "en";
      const cs = "cs";

      // set czech lang
      wmt.setAcceptLanguage(cs);
      await wmt.operations.getOperations(requestProcessor: (headers) {
        expect(headers.value("accept-language"), cs);
      });

      // set eng lang
      wmt.setAcceptLanguage(en);
      await wmt.inbox.getMessageList(0, 50, false, requestProcessor: (headers) {
        expect(headers.value("accept-language"), en);
      });
    });

    test("testPushRegistration", () async {
      final List<WMTPushPlatform>  platforms = [  
        /// apns testing
        WMTPushPlatform.apns("token", environment: WMTPushApnsEnvironment.development),
        WMTPushPlatform.apns("token", environment: WMTPushApnsEnvironment.production),
        WMTPushPlatform.apns("token"),
        WMTPushPlatform.apns("token").supportLegacyServer(),

        // fcm testing
        WMTPushPlatform.fcm("token"),
        WMTPushPlatform.fcm("token").supportLegacyServer(),

        // hms testing
        WMTPushPlatform.hms("token"),
        WMTPushPlatform.hms("token").supportLegacyServer(),
      ];

      for (final platform in platforms) {
        // we just expect not to throw here
        await wmt.push.register(platform);
      }
    });

    Future<int> fetchUnreadMessagesCount() async {
      final resp = await wmt.inbox.getUnreadCount();
      return resp.countUnread;
    }

    compareMessages(List<NewInboxMessage> expected, List<WMTInboxMessage> received) {
      expect(expected.length, received.length);
      for (var detail in expected) {
        final message = received.where( (it) => it.id == detail.id ).firstOrNull;
        if (message == null) {
            throw Exception("Message with ID ${detail.id} not found");
        }

        expect(detail.subject, message.subject);
        expect(detail.read, message.read);
        expect(detail.summary, message.summary);
        expect(detail.type, message.type.value);
      }
    }

    test("testInboxMessages", () async {
      const messagesToTest = 5;
      expect(await fetchUnreadMessagesCount(), 0);

      // Now prepare messages
      final messages = await helper.createInboxMessages(messagesToTest);
      expect(await fetchUnreadMessagesCount(), messagesToTest);

      // Read first page
      final messagesList = await wmt.inbox.getMessageList(0, 50, false);
      expect(messagesList, isNotNull);
      compareMessages(messages, messagesList);

      // Now read first message's detail
      final firstMessage = messages[0];
      final detail = await wmt.inbox.getMessageDetail(firstMessage.id);

      expect(firstMessage.id, detail.id);
      expect(firstMessage.subject, detail.subject);
      expect(firstMessage.summary, detail.summary);
      expect(firstMessage.body, detail.body);
      expect(firstMessage.read, detail.read);
      expect(firstMessage.type, detail.type.value);
    });

    test("testMarkMessageRead", () async {
      const count = 4;
      final messages = await helper.createInboxMessages(count);
      final receivedMessages = await wmt.inbox.getMessageList(0, 50, false);

      compareMessages(messages, receivedMessages);

      // Mark first as read and receive its detail
      final messageId = receivedMessages[0].id;
      await wmt.inbox.markRead(messageId); // expect no exception here

      // Now get message detail
      final messageDetail = await wmt.inbox.getMessageDetail(messageId);
      expect(messageDetail.read, isTrue);
    });
  });
}

class _PollingListener implements WMTOperationsListener {
  final void Function(List<WMTUserOperation>, List<WMTUserOperation>, List<WMTUserOperation>)? onChanged;
  final void Function(bool)? onLoading;
  final void Function(Object)? onError;

  _PollingListener({ this.onChanged, this.onLoading, this.onError });

  @override
  void operationsChanged(List<WMTUserOperation> operations, List<WMTUserOperation> removed, List<WMTUserOperation> added) {
    onChanged?.call(operations, removed, added);
  }

  @override
  void operationsFailed(Object error) => onError?.call(error);

  @override
  void operationsLoading(bool loading) => onLoading?.call(loading);
}
