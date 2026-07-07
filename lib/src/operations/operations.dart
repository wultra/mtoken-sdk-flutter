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

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import '../core/exception.dart';
import '../core/logger.dart';
import '../utils/response_processor.dart';
import '../networking/networking.dart';
import 'online_operation.dart';
import 'operation_proximity_check.dart';
import 'qr_operation.dart';
import 'rejection_reason.dart';
import 'user_operation.dart';

/// Operations networking layer for Wultra Mobile Token API.
class WMTOperations extends WMTNetworking {

  /// Constructor that initializes the operations networking layer.
  /// 
  /// Params:
  /// - [powerAuth] is the PowerAuth instance used for signing requests.
  /// - [baseUrl] is the base URL of the Wultra Mobile Token API (usually ending with /enrollment-server).
  WMTOperations(PowerAuth powerAuth, String baseUrl) : super(powerAuth, baseUrl, "WMTOperations");

  /// Retrieves user operations that are pending for approval or rejection.
  /// 
  /// Params:
  /// - [requestProcessor] You may modify the request headers via this processor.
  /// 
  /// Returns list of operations.
  Future<List<WMTUserOperation>> getOperations({ WMTRequestProcessor? requestProcessor }) async {

    final response = await postSignedWithToken(
      {}, 
      PowerAuthAuthentication.possession(), 
      "/api/auth/token/app/operation/list", 
      "possession_universal",
      requestProcessor: requestProcessor,
    );

    return processResponse("operations list", () {
      final list = response as List<dynamic>;
      return list.map((item) => WMTUserOperation.fromJson(item as Map<String, dynamic>)).toList();
    });
  }

  /// Retrieves operation detail based on operation ID.
  /// 
  /// - [operationId] ID of the operation.
  /// - [requestProcessor] You may modify the request headers via this processor.
  /// 
  /// Detail of the operation
  Future<WMTUserOperation> getDetail(String operationId, { WMTRequestProcessor? requestProcessor }) async {
    final response = await postSignedWithToken(
      { "requestObject": { "id": operationId } },
      PowerAuthAuthentication.possession(),
      "/api/auth/token/app/operation/detail",
      "possession_universal",
      requestProcessor: requestProcessor,
    );

    return processResponse("operation detail", () {
      return WMTUserOperation.fromJson(response);
    });
  }
  
  /// Retrieves the history of user operations with their current status.
  /// 
  /// Params:
  /// - [authentication] A multi-factor authentication object for signing. 2FA should be used (password or biometrics).
  /// - [requestProcessor] You may modify the request headers via this processor.
  /// 
  /// Returns list of operations.
  Future<List<WMTUserOperation>> getHistory(PowerAuthAuthentication authentication, { WMTRequestProcessor? requestProcessor }) async {
    final response = await postSigned(
      {},
      authentication,
      "/api/auth/token/app/operation/history",
      "/operation/history",
      requestProcessor: requestProcessor,
    );

    return processResponse("operations history", () {
      final list = response as List<dynamic>;
      return list.map((item) => WMTUserOperation.fromJson(item as Map<String, dynamic>)).toList();
    });
  }

  /// Authorize operation with given PowerAuth authentication object.
  /// 
  /// If the operation has a proximity check, the SDK automatically adjusts its timestamps
  /// using server-synchronized time. If time is not yet synchronized, the SDK will
  /// synchronize it before proceeding with the authorization.
  /// 
  /// Params:
  /// - [operation] Operation to authorize.
  /// - [authentication] A multi-factor authentication object for signing. 2FA should be used (password or biometrics).
  /// - [requestProcessor] You may modify the request headers via this processor.
  Future<void> authorize(WMTOnlineOperation operation, PowerAuthAuthentication authentication, { WMTRequestProcessor? requestProcessor }) async {

    final proximityCheck = operation.proximityCheck;
    Object? proximityRequest;
    if (proximityCheck != null) {
      await _ensureTimeSynchronized();
      proximityRequest = await _buildProximityCheckRequestData(proximityCheck);
    }

    await _postAuthorize(operation, proximityRequest, authentication, requestProcessor);
  }

  /// Ensures that the local time is synchronized with the PowerAuth server.
  ///
  /// If the time is not synchronized yet, it synchronizes it. Throws when the synchronization fails.
  Future<void> _ensureTimeSynchronized() async {
    final timeService = powerAuth.timeSynchronizationService;
    if (await timeService.isTimeSynchronized()) {
      Log.debug("Proximity check: time already synchronized.");
      return;
    }
    Log.info("Proximity check: time not synchronized, synchronizing before authorize.");
    await timeService.synchronizeTime();
  }

  /// Builds the proximity check request data with timestamps adjusted to the server-synchronized time.
  ///
  /// Must only be called when the time is synchronized with the server (see [_ensureTimeSynchronized]).
  Future<Map<String, Object>> _buildProximityCheckRequestData(WMTOperationProximityCheck proximityCheck) async {
    final timeService = powerAuth.timeSynchronizationService;
    final localTimeAdjustment = await timeService.localTimeAdjustment();
    final adjustedReceived = proximityCheck.timestampReceived.millisecondsSinceEpoch + localTimeAdjustment;
    final timestampSent = await timeService.currentTime();

    if (adjustedReceived > timestampSent) {
      throw WMTException(
        description:
            "Proximity check timestamp is invalid"
      );
    }

    Log.debug(() =>
      "Proximity check timestamps: "
      "timestampReceived=${proximityCheck.timestampReceived.millisecondsSinceEpoch}, "
      "adjustedReceived=$adjustedReceived, "
      "timestampSent(serverTime)=$timestampSent, "
      "localTimeAdjustment=${localTimeAdjustment}ms"
    );

    return { 
      "otp": proximityCheck.totp,
      "type": proximityCheck.type.serialized,
      "timestampReceived": adjustedReceived,
      "timestampSent": timestampSent
    };
  }

  /// Posts the authorize request to the server.
  Future<void> _postAuthorize(WMTOnlineOperation operation, Object? proximityRequest, PowerAuthAuthentication authentication, WMTRequestProcessor? requestProcessor) async {
    await postSigned(
      { "requestObject": { "id": operation.id, "data": operation.data, "proximityCheck": proximityRequest, "mobileTokenData": operation.mobileTokenData } },
      authentication,
      "/api/auth/token/app/operation/authorize",
      "/operation/authorize",
      requestProcessor: requestProcessor,
    );
  }

  /// Reject operation with a reason.
  /// 
  /// Params: 
  /// - [operationId] ID of the operation.
  /// - [reason] Reason for the rejection.
  /// - [requestProcessor] You may modify the request headers via this processor.
  Future<void> reject(String operationId, WMTRejectionReason reason, { WMTRequestProcessor? requestProcessor }) async {
    await postSigned(
      { "requestObject": { "id": operationId, "reason": reason.serialized } },
      PowerAuthAuthentication.possession(),
      "/api/auth/token/app/operation/cancel",
      "/operation/cancel",
      requestProcessor: requestProcessor,
    );
  }

  /// Sign offline QR operation with provided authentication.
  /// 
  /// Note that the operation will be signed even if the authentication object is
  /// not valid as it cannot be verified on the server.
  ///
  /// Params:
  /// - [operation] Operation to approve
  /// - [authentication] A multi-factor authentication object for signing. 2FA should be used (password or biometrics).
  /// - [uriId] Custom signature URI ID of the operation. Use URI ID under which the operation was
  /// created on the server. Default value is `/operation/authorize/offline`.
  /// 
  /// Returns OTP code to display to the user
  Future<String> authorizeOffline(WMTQROperation operation, PowerAuthAuthentication authentication, {String uriId = "/operation/authorize/offline"}) async {
    return await powerAuth.offlineSignature(authentication, uriId, operation.nonce, operation.dataForOfflineSining);
  }

  /// Assigns the 'non-personalized' operation to the user.
  /// 
  /// Params:
  ///  - [operationId] ID of the operation which will be claimed to belong to the user.
  ///  - [requestProcessor] You may modify the request via this processor. It's highly recommended to only modify HTTP headers.
  /// 
  /// Returns operation detail
  Future<WMTUserOperation> claim(String operationId, { WMTRequestProcessor? requestProcessor }) async {
    final response = await postSignedWithToken(
      { "requestObject": { "id": operationId } },
      PowerAuthAuthentication.possession(),
      "/api/auth/token/app/operation/detail/claim",
      "possession_universal",
      requestProcessor: requestProcessor,
    );

    return processResponse("operation claim", () {
      return WMTUserOperation.fromJson(response);
    });
  }
}
