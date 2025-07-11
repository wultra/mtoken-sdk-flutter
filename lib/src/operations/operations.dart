import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:mtoken_sdk_flutter/src/networking/networking.dart';
import 'package:mtoken_sdk_flutter/src/operations/user_operation.dart';

class WMTOperations extends WMTNetworking {

  WMTOperations(super.powerAuth, super.baseUrl);

  // TODO: Add support for request processor

  /// Retrieves user operations that are pending for approval or rejection.
  Future<List<WMTUserOperation>> getOperations() async {

      final response = await postSignedWithToken(
        "{}", 
        PowerAuthAuthentication.possession(), 
        "/api/auth/token/app/operation/list", 
        "possession_universal",
        );

        final list = response['responseObject'] as List<dynamic>;
        return list.map((item) => WMTUserOperation.fromJson(item as Map<String, dynamic>)).toList();
  }

}