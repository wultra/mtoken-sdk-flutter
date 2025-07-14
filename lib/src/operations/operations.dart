import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:mtoken_sdk_flutter/src/networking/networking.dart';
import 'package:mtoken_sdk_flutter/src/operations/online_operation.dart';
import 'package:mtoken_sdk_flutter/src/operations/rejection_reason.dart';
import 'package:mtoken_sdk_flutter/src/operations/user_operation.dart';

class WMTOperations extends WMTNetworking {

  WMTOperations(super.powerAuth, super.baseUrl);

  /// Retrieves user operations that are pending for approval or rejection.
  /// 
  /// [requestProcessor] You may modify the request headers via this processor.
  Future<List<WMTUserOperation>> getOperations({ WMTRequestProcessor? requestProcessor }) async {

    final response = await postSignedWithToken(
      {}, 
      PowerAuthAuthentication.possession(), 
      "/api/auth/token/app/operation/list", 
      "possession_universal",
      requestProcessor: requestProcessor,
    );

    final list = response as List<dynamic>;
    return list.map((item) => WMTUserOperation.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Retrieves operation detail based on operation ID.
  /// 
  /// [operationId] ID of the operation.
  /// [requestProcessor] You may modify the request headers via this processor.
  Future<WMTUserOperation> getDetail(String operationId, { WMTRequestProcessor? requestProcessor }) async {
    final response = await postSignedWithToken(
      { "requestObject": { "id": operationId } },
      PowerAuthAuthentication.possession(),
      "/api/auth/token/app/operation/detail",
      "possession_universal",
      requestProcessor: requestProcessor,
    );

    return WMTUserOperation.fromJson(response);
  }
  
  /// Retrieves the history of user operations with their current status.
  /// 
  /// [authentication] A multi-factor authentication object for signing. 2FA should be used (password or biometrics).
  /// [requestProcessor] You may modify the request headers via this processor.
  Future<List<WMTUserOperation>> getHistory(PowerAuthAuthentication authentication, { WMTRequestProcessor? requestProcessor }) async {
    final response = await postSignedWithToken(
      {},
      authentication,
      "/api/auth/token/app/operation/history",
      "possession_universal",
      requestProcessor: requestProcessor,
    );

    final list = response as List<dynamic>;
    return list.map((item) => WMTUserOperation.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Authorize operation with given PowerAuth authentication object.
  /// 
  /// [operation] Operation to authorize.
  /// [authentication] A multi-factor authentication object for signing. 2FA should be used (password or biometrics).
  /// [requestProcessor] You may modify the request headers via this processor.
  Future<void> auhtorize(WMTOnlineOperation operation, PowerAuthAuthentication authentication, { WMTRequestProcessor? requestProcessor }) async {

    final opProxyCheck = operation.proximityCheck;
    Object? proximityRequest;
    if (opProxyCheck != null) {
        proximityRequest = { "otp": opProxyCheck.totp, "type": opProxyCheck.type.serialized, "timestampReceived": opProxyCheck.timestampReceived, "timestampSent": DateTime.now() };
    }

    await postSigned(
      { "requestObject": { "id": operation.id, "data": operation.data, "proximityCheck": proximityRequest, "mobileTokenData": operation.mobileTokenData } },
      authentication,
      "/api/auth/token/app/operation/authorize",
      "/operation/authorize",
      requestProcessor: requestProcessor,
    );
  }

  ///Reject operation with a reason.
  /// 
  /// [operationId] ID of the operation.
  /// [reason] Reason for the rejection.
  /// [requestProcessor] You may modify the request headers via this processor.
  Future<void> reject(String operationId, WMTRejectionReason reason, { WMTRequestProcessor? requestProcessor }) async {
    await postSigned(
      { "requestObject": { "id": operationId, "reason": reason.serialized } },
      PowerAuthAuthentication.possession(),
      "/api/auth/token/app/operation/cancel",
      "/operation/cancel",
      requestProcessor: requestProcessor,
    );
  }
}