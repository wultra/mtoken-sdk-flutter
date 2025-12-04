import 'dart:convert';
import 'dart:io';

import 'package:example/test_utils/integration_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:mtoken_sdk_flutter/mtoken_sdk_flutter.dart';

void main() {
  group("oidc tests", () {
    @protected late IntegrationHelper helper;
    @protected late PowerAuth sdk;
    @protected late WultraMobileToken wmt;

    setUpAll(() async {
      WMTLogger.verbosity = WMTLoggerVerbosity.debug;
    });

    setUp(() async {
      sdk = PowerAuth(IntegrationHelper.randomString(30));
      helper = IntegrationHelper(sdk);
      await helper.configure();
      wmt = sdk.createMobileToken();
    });

    tearDown(() async {
      await helper.cleanup();
    });

    test("testGetConfigFails", () async {
      const nonValidProviderId = "xxx";

      try {
        final config = await wmt.oidc.getConfig(nonValidProviderId);
        fail("Expected getConfig() to fail for invalid providerId, but it succeeded with: $config");
      } on WMTException catch (e) {
        expect(e.responseError, isNotNull);
      } catch (e) {
        fail("Unexpected exception type: $e");
      }
    });

    test("testGetConfigSucceed", () async {
      final providers = helper.getOIDCProperties();
      if (providers == null || providers.providerId.isEmpty) {
        print("If you want to test OIDC PKCE, provide providers in the IntegrationHelper.");
        return;
      }

      final config = await wmt.oidc.getConfig(providers.providerId);

      expect(config.authorizeUri, isNotNull);
      expect(config.providerId, isNotNull);
      expect(config.scopes, isNotNull);
      expect(config.clientId, isNotNull);
      expect(config.redirectUri, isNotNull);
      expect(config.pkceEnabled, isFalse);
    });

    test("testGetConfigPKCESucceed", () async {
      final providers = helper.getOIDCProperties();
      if (providers == null || providers.providerIdPkce.isEmpty) {
        print("If you want to test OIDC PKCE, provide providers in the IntegrationHelper.");
        return;
      }

      final config = await wmt.oidc.getConfig(providers.providerIdPkce);

      expect(config.authorizeUri, isNotNull);
      expect(config.providerId, isNotNull);
      expect(config.scopes, isNotNull);
      expect(config.clientId, isNotNull);
      expect(config.redirectUri, isNotNull);
      expect(config.pkceEnabled, isTrue);
    });

    test("testOIDCPreparesAuthorizationData", () async {
      final providers = helper.getOIDCProperties();
      if (providers == null || providers.providerIdPkce.isEmpty) {
        print("If you want to test OIDC auth data, provide providerIdPkce in the IntegrationHelper.");
        return;
      }

      final config = await wmt.oidc.getConfig(providers.providerIdPkce);
      expect(config, isNotNull);

      try {
        final authData = await wmt.oidc.prepareAuthorizationData(config);

        expect(authData.authorizeUri, isNotNull, reason: "Authorization URI should not be null");
        expect(authData.state, isNotNull, reason: "State should not be null");
        expect(authData.nonce, isNotNull, reason: "Nonce should not be null");
        expect(
          authData.codeVerifier,
          isNotNull,
          reason: "Code verifier should not be null for PKCE provider",
        );
      } on WMTException catch (e) {
        fail("Authorization data preparation failed: $e");
      }
    });

    /// The entire OIDC activation flow is highly dependent on third-party implementations.
    /// This flow was tested using our configuration with `auth0.com`.
    /// Below is a summary of the process outside our system:
    ///
    /// 1. GET request with the authorization URI → Extract the redirect URI and `authState` from the response.
    /// 2. Send a POST request to the login URI with the body containing `username`, `password`, and `authState` → Extract the resume URI from the response.
    /// 3. Send a GET request to the resume URI → Extract the deeplink URI containing the authorization `code`.
    ///
    /// ## Redirect Handling
    /// Unlike typical HTTP clients that automatically follow redirects, this test
    /// deliberately disables automatic redirect handling and inspects `Location`
    /// headers manually. This lets us capture intermediate redirects and support
    /// flows with mixed HTTP methods (e.g. GET → redirect → POST → redirect → GET → redirect),
    /// while still maintaining a single logical browser-like session.
    ///
    /// ## Testing Requirements
    /// You must also provide the `username` and `password` of your testing Auth0 account
    /// when running this flow. and `providerIdPkce` in the config file
//     test("testOIDCActivationFlow", () async {
//       final providers = helper.getOIDCProperties();

//       final testUsername = providers?.oidcUsername ?? fail("OIDC username is not set.");
//       final testPassword = providers?.oidcPassword ?? fail("OIDC password is not set.");

//       if (providers == null || providers.providerIdPkce.isEmpty) {
//         print(
//           "If you want to test OIDC activation flow, provide providerIdPkce in IntegrationHelper.",
//         );
//         return;
//       }

//       final providerIdPkce = providers.providerIdPkce;

//       // 1) Fetch OIDC config -> scope of this SDK
//       final config = await _fetchOidcConfig(wmt.oidc, providerIdPkce);

//       // 2) Prepare authorization data (state, nonce, PKCE, ...). -> scope of this SDK
//       final oidcAuthData = await _prepareAuthorizationData(wmt.oidc, config);

//       // 3) Drive the external OIDC login flow (GET -> POST -> GET) against Auth0. -> out of the scope of this SDK
//       final redirectUri = await _loginWithAuth0(
//         oidcAuthData.authorizeUri,
//         testUsername,
//         testPassword,
//       );

//       // 4) Process the final deeplink (scheme://oidc?code=...) -> out of the scope of this SDK
//       final activationAttributes = WMTOIDCUtils.processWebCallback(
//         uri: redirectUri,
//         authData: oidcAuthData,
//       );

//       // 5) Create PowerAuth activation from OIDC attributes. -> PA mobile SDK scope but extension method is scope of this SDK
//       final activationResult = await _createPowerAuthActivation(sdk, activationAttributes);
//       expect(activationResult.activationFingerprint, isNotEmpty);

//       // 6) Commit activation so we end up with a fully valid activation. - PA mobile SDK scope
//       final auth = PowerAuthAuthentication.persistWithPassword(
//         await ActivationCredentials().validPasswordObject(),
//       );
//       await sdk.persistActivation(auth);

//       expect(await sdk.hasValidActivation(), isTrue);
//     });
  });
}

// // -----------------------------------------------------------------------------
// // Helpers
// // -----------------------------------------------------------------------------

// /// Thin wrapper around `getConfig(...)` to keep the test body clean.
// Future<WMTOIDCConfig> _fetchOidcConfig(
//     WMTOIDC oidc, 
//     String providerId,
// ) async {
//   try {
//     return await oidc.getConfig(providerId);
//   } on WMTException catch (e) {
//     fail("Failed to fetch OIDC configuration (providerId: $providerId): $e");
//   }
// }

// /// Thin wrapper around `prepareAuthorizationData(...)` to keep the test body clean.
// Future<WMTOIDCAuthorizationRequest> _prepareAuthorizationData(
//   WMTOIDC oidc,
//   WMTOIDCConfig config,
// ) async {
//   try {
//     return await oidc.prepareAuthorizationData(config);
//   } on WMTException catch (e) {
//     fail("Failed to prepare OIDC authorization data: $e");
//   }
// }

// /// Performs the OIDC login flow against Auth0 and returns the final deeplink URL
// /// containing the authorization `code`.
// Future<Uri> _loginWithAuth0(
//   Uri authorizeUri,
//   String username,
//   String password,
// ) async {
//   print("Auth0 login flow starting with URL: $authorizeUri");

//   final client = HttpClient();
//   final cookieJar = <Cookie>[];

//   try {
//     // Step 1: GET authorize URL -> redirect to login page.
//     final authStep1 = await _performRequest(
//       client: client,
//       cookieJar: cookieJar,
//       uri: authorizeUri,
//       method: "GET",
//       body: null,
//     );

//     final authRedirectUrl = authStep1.redirectUri;
//     if (authRedirectUrl == null) {
//       throw Exception("Redirect URL not found in authorize step.");
//     }

//     // If the redirect already contains `code`, the user is already logged in.
//     if (authRedirectUrl.toString().contains("code")) {
//       return authRedirectUrl;
//     }

//     final authState = authStep1.authState;
//     if (authState == null) {
//       throw Exception("State parameter not found in authorize step.");
//     }

//     // Step 2: POST login credentials.
//     final loginBody =
//         "username=${Uri.encodeQueryComponent(username)}"
//         "&password=${Uri.encodeQueryComponent(password)}"
//         "&state=${Uri.encodeQueryComponent(authState)}";

//     final loginStep = await _performRequest(
//       client: client,
//       cookieJar: cookieJar,
//       uri: authRedirectUrl,
//       method: "POST",
//       body: loginBody,
//     );

//     final loginRedirectUrl = loginStep.redirectUri;
//     if (loginRedirectUrl == null) {
//       throw Exception("Final redirect URI not found after login.");
//     }

//     // Step 3: GET resume URL – should end with deeplink (mtoken://oidc?code=...).
//     final resumeStep = await _performRequest(
//       client: client,
//       cookieJar: cookieJar,
//       uri: loginRedirectUrl,
//       method: "GET",
//       body: null,
//     );

//     final deeplinkUrl = resumeStep.redirectUri;
//     if (deeplinkUrl == null) {
//       throw Exception("Deeplink URL with auth code not found in resume step.");
//     }

//     return deeplinkUrl;
//   } finally {
//     client.close();
//   }
// }

// /// Executes a single HTTP step with manual redirect handling and simple cookie
// /// management to mimic a browser session.
// Future<_StepResult> _performRequest({
//   required HttpClient client,
//   required List<Cookie> cookieJar,
//   required Uri uri,
//   required String method, // "GET" or "POST"
//   String? body,
// }) async {
//   print("OIDC step: $method $uri");

//   late HttpClientRequest request;

//   if (method == 'GET') {
//     request = await client.getUrl(uri);
//   } else if (method == 'POST') {
//     request = await client.postUrl(uri);
//   } else {
//     throw ArgumentError('Unsupported method: $method');
//   }

//   // configure before sending
//   request.followRedirects = false;
//   request.maxRedirects = 0;

//   // attach cookies for this flow only
//   for (final cookie in cookieJar) {
//     request.cookies.add(cookie);
//   }

//   if (method == 'POST') {
//     request.headers.set(
//       HttpHeaders.contentTypeHeader,
//       'application/x-www-form-urlencoded',
//     );
//   }

//   request.headers.set(
//     HttpHeaders.userAgentHeader,
//     'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)',
//   );

//   if (method == 'POST' && body != null) {
//     request.write(body);
//   }

//   final response = await request.close();

//   final statusCode = response.statusCode;
//   final headers = response.headers;
//   final bodyText = await response.transform(utf8.decoder).join();

//   print('OIDC step: status=$statusCode url=$uri');
//   print('Headers: ${_headersToDebugString(headers)}');
//   if (bodyText.isNotEmpty) {
//     final truncated =
//         bodyText.length > 300 ? bodyText.substring(0, 300) : bodyText;
//     print('Body: $truncated');
//   }

//   // update cookies for this flow
//   final setCookieHeaders = headers[HttpHeaders.setCookieHeader] ?? [];
//   for (final sc in setCookieHeaders) {
//     try {
//       final cookie = Cookie.fromSetCookieValue(sc);
//       cookieJar.removeWhere((c) =>
//           c.name == cookie.name &&
//           (c.domain == cookie.domain || cookie.domain == null) &&
//           (c.path == cookie.path || cookie.path == null));
//       cookieJar.add(cookie);
//     } catch (_) {
//       // ignore malformed cookies
//     }
//   }

//   if (statusCode >= 300 && statusCode < 400) {
//     final locationHeader = headers.value('location');
//     if (locationHeader == null) {
//       throw Exception("Redirect status $statusCode but no Location header for URL: $uri");
//     }

//     final redirectUri = uri.resolve(locationHeader);
//     print('Constructed redirect URL from base+Location: $redirectUri');

//     final authState = redirectUri.queryParameters['state'];

//     return _StepResult(
//       redirectUri: redirectUri,
//       authState: authState,
//     );
//   }

//   if (statusCode != 200) {
//     throw Exception(
//       "Unexpected status code $statusCode for URL: $uri\n"
//       "Body (truncated): ${bodyText.substring(0, bodyText.length.clamp(0, 300))}",
//     );
//   }

//   return _StepResult(
//     redirectUri: uri,
//     authState: uri.queryParameters['state'],
//   );
// }

// String _headersToDebugString(HttpHeaders headers) {
//   final buffer = StringBuffer('{');
//   headers.forEach((k, v) {
//     buffer.write(' "$k": "${v.join(", ")}",');
//   });
//   buffer.write(' }');
//   return buffer.toString();
// }

// class _StepResult {
//   final Uri? redirectUri;
//   final String? authState;

//   _StepResult({this.redirectUri, this.authState});
// }

// /// Creates a PowerAuth activation from OIDC attributes and returns the result.
// Future<PowerAuthCreateActivationResult> _createPowerAuthActivation(
//   PowerAuth sdk,
//   WMTOIDCPowerAuthActivationAttributes attrs,
// ) async {
//   try {
//     final result = await sdk.createOidcActivation(
//       attrs,
//       activationName: "Flutter Test2",
//     );
//     expect(result, isNotNull, reason: "Activation result should not be null");
//     return result;
//   } on Exception catch (e) {
//     fail("Failed to create PowerAuth activation via OIDC: $e");
//   }
// }
