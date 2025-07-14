
import 'package:mtoken_sdk_flutter/src/operations/operation_proximity_check.dart';

/// An abstract class that defines minimum data needed for calculating the operation signature
/// and sending it to confirmation endpoint.
abstract class WMTOnlineOperation {
  
  /// Unique operation identifier. 
  String get id;

  /// Actual data that will be signed.
  /// 
  /// This shouldn't be visible to the user.
  String get data;

  /// Additional information with proximity check data 
  abstract WMTOperationProximityCheck? proximityCheck;

  /// Additional mobile token data for authorization (available with PowerAuth server 1.10+) 
  abstract Object? mobileTokenData; // TODO: add test for serialization
}