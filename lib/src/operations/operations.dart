import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import '../networking/networking.dart';
import 'online_operation.dart';
import 'qr_operation.dart';
import 'rejection_reason.dart';
import 'user_operation.dart';

class WMTOperations extends WMTNetworking {

  WMTOperations(super.powerAuth, super.baseUrl);

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

    final list = response as List<dynamic>;
    return list.map((item) => WMTUserOperation.fromJson(item as Map<String, dynamic>)).toList();
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

    return WMTUserOperation.fromJson(response);
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

    final list = response as List<dynamic>;
    return list.map((item) => WMTUserOperation.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Authorize operation with given PowerAuth authentication object.
  /// 
  /// Params:
  /// - [operation] Operation to authorize.
  /// - [authentication] A multi-factor authentication object for signing. 2FA should be used (password or biometrics).
  /// - [requestProcessor] You may modify the request headers via this processor.
  Future<void> auhtorize(WMTOnlineOperation operation, PowerAuthAuthentication authentication, { WMTRequestProcessor? requestProcessor }) async {

    final opProxyCheck = operation.proximityCheck;
    Object? proximityRequest;
    if (opProxyCheck != null) {
        proximityRequest = { "otp": opProxyCheck.totp, "type": opProxyCheck.type.serialized, "timestampReceived": opProxyCheck.timestampReceived.millisecondsSinceEpoch, "timestampSent": DateTime.now().millisecondsSinceEpoch };
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

    return WMTUserOperation.fromJson(response);
  }
}