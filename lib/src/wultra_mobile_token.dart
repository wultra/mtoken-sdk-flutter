
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:mtoken_sdk_flutter/src/core/logger.dart';
import 'package:mtoken_sdk_flutter/src/networking/user_agent.dart';
import 'package:mtoken_sdk_flutter/src/operations/operations.dart';

/// MobileToken class exposes APIs that enable:
///  - Fetching, authorizing or rejecting basic
///  - operations created in the PowerAuth stack.
///  - Push notifications enrollment.
///  - Inbox message management.
class WultraMobileToken {
  
  /// Operations manager. Use for fetching pending list, approving the operations etc.
  final WMTOperations operations;

  // Private constructor to enforce the use of the factory method.
  WultraMobileToken._(this.operations);

  /// 
  /// [powerAuth] PowerAuth instance. Needs to be activated when calling any method of this class - othewise error will be thrown.
  /// 
  /// [acceptLanguage] Optionally sets the accept language for the outgoing requests headers for `operations`, `push` and `inbox` objects.
  ///                  The default value is "en".
  ///                  The value can be further modified in the each service object individualy.
  ///                  Standard RFC "Accept-Language" https://tools.ietf.org/html/rfc7231#section-5.3.5
  ///                  Response texts are based on this setting. For example when "de" is set, server
  ///                  will return operation texts in german (if available).
  /// 
  /// [userAgent] Optionally sets the User agent that will be used in a HTTP hader. 
  ///             Note that user-agent can be overriden by request processor in each API call.
  ///             The default value is [WMTUserAgent.libraryDefault], which is a user agent that contains the library name and version. 
  /// 
  /// Can throw when a null or invalid `baseEndpointUrl` is set in the `PowerAuth` instance.
  factory WultraMobileToken.create({required PowerAuth powerAuth, String? acceptLanguage, WMTUserAgent? userAgent}) {

    final baseURL = powerAuth.configuration?.baseEndpointUrl;

    if (baseURL == null || baseURL.isEmpty) {
      throw ArgumentError("PowerAuth configuration must contain a valid base endpoint URL.");
    }

    final operations = WMTOperations(powerAuth, baseURL);

    operations.acceptLanguage = acceptLanguage ?? "en";

    final agent = userAgent ?? WMTUserAgent.libraryDefault();
    operations.userAgent = agent;

    WMTLogger.debug("Mobile Token object created with:");
    WMTLogger.debug(" - baseURL: $baseURL");
    WMTLogger.debug(" - acceptLanguage: ${acceptLanguage}");
    WMTLogger.debug(" - userAgent: ${agent.description}");

    return WultraMobileToken._(operations);
  }
}

extension PowerAuthExtension on PowerAuth {

  /// Creates a [WultraMobileToken] instance using the current PowerAuth instance.
  /// 
  /// URL from the `PowerAuthSDK` instance is used for services.
  /// 
  /// [acceptLanguage] Optionally sets the accept language for the outgoing requests headers for `operations`, `push` and `inbox` objects.
  ///                  The default value is "en".
  ///                  The value can be further modified in the each service object individualy.
  ///                  Standard RFC "Accept-Language" https://tools.ietf.org/html/rfc7231#section-5.3.5
  ///                  Response texts are based on this setting. For example when "de" is set, server
  ///                  will return operation texts in german (if available).
  /// 
  /// [userAgent] Optionally sets the User agent that will be used in a HTTP hader.
  ///             Note that user-agent can be overriden by request processor in each API call.
  ///             The default value is [WMTUserAgent.libraryDefault], which is a user agent that contains the library name and version.
  WultraMobileToken createMobileToken({String? acceptLanguage, WMTUserAgent? userAgent}) {
    return WultraMobileToken.create(powerAuth: this, acceptLanguage: acceptLanguage, userAgent: userAgent);
  }
}