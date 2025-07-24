import 'package:flutter_test/flutter_test.dart';
import 'package:mtoken_sdk_flutter/mtoken_sdk_flutter.dart';
import 'package:mtoken_sdk_flutter/src/operations/pac_utils.dart';

void main() {

  group("pacUtilsTests", () {
    test('testParseQRCodeWithEmptyCode', () {
      
      final code = "";
      expect(() => WMTPACUtils.parseQRCode(code), throwsA(isA<WMTException>()));
    });

    test("testQRPACParserWithShortInvalidCode", () {
      final code = "abc";
      expect(() => WMTPACUtils.parseQRCode(code), throwsA(isA<WMTException>()));
    });

    test("testQRTPACParserWithValidDeeplinkCode", () {
      final code = "scheme://operation?oid=6a1cb007-ff75-4f40-a21b-0b546f0f6cad&potp=73743194";
      final parsed = WMTPACUtils.parseQRCode(code);
      expect(parsed.potp, "73743194");
      expect(parsed.oid, "6a1cb007-ff75-4f40-a21b-0b546f0f6cad");
    });

    test("testQRTPACParserWithValidDeeplinkCodeAndBase64EncodedOID", () {
      final code = "scheme://operation?oid=E%2F%2BDRFVmd4iZABEiM0RVZneImQARIjNEVWZ3iJkAESIzRFVmd4iZAA%3D&totp=12345678";
      final parsed = WMTPACUtils.parseQRCode(code);
      expect(parsed.potp, "12345678");
      expect(parsed.oid, "E/+DRFVmd4iZABEiM0RVZneImQARIjNEVWZ3iJkAESIzRFVmd4iZAA=");
    });

    test("testQRPACParserWithValidJWT", () {
      final code = "eyJhbGciOiJub25lIiwidHlwZSI6IkpXVCJ9.eyJvaWQiOiIzYjllZGZkMi00ZDgyLTQ3N2MtYjRiMy0yMGZhNWM5OWM5OTMiLCJwb3RwIjoiMTQzNTc0NTgifQ==";
      final parsed = WMTPACUtils.parseQRCode(code);
      expect(parsed.potp, "14357458");
      expect(parsed.oid, "3b9edfd2-4d82-477c-b4b3-20fa5c99c993");
    });

    test("testQRPACParserWithValidJWTWithoutPadding", () {
      final code = "eyJ0eXAiOiJKV1QiLCJhbGciOiJub25lIn0.eyJvaWQiOiJMRG5JY0NjRGhjRHdHNVNLejhLeWdQeG9PbXh3dHpJc29zMEUrSFBYUHlvIiwicG90cCI6IjU4NTkwMDU5In0";
      final parsed = WMTPACUtils.parseQRCode(code);
      expect(parsed.potp, "58590059");
      expect(parsed.oid, "LDnIcCcDhcDwG5SKz8KygPxoOmxwtzIsos0E+HPXPyo");
    });

    test("testQRPACParserWithInvalidJWT", () {
      expect(() => WMTPACUtils.parseQRCode("eyJhbGciOiJub25lIiwidHlwZSI6IkpXVCJ9eyJvaWQiOiIzYjllZGZkMi00ZDgyLTQ3N2MtYjRiMy0yMGZhNWM5OWM5OTMiLCJwb3RwIjoiMTQzNTc0NTgifQ=="), throwsA(isA<WMTException>()));
    });

    test("testQRPACParserWithInvalidJWT2", () {
      expect(() => WMTPACUtils.parseQRCode("eyJ0eXAiOiJKV1QiLCJhbGciOiJub25lIn0.1eyJvaWQiOiJMRG5JY0NjRGhjRHdHNVNLejhLeWdQeG9PbXh3dHpJc29zMEUrSFBYUHlvIiwicG90cCI6IjU4NTkwMDU5In0"), throwsA(isA<WMTException>()));
    });

    test("testQRPACParserWithInvalidJWT3", () {
      expect(() => WMTPACUtils.parseQRCode(""), throwsA(isA<WMTException>()));
    });

    test("testQRPACParserWithInvalidJWT4", () {
      expect(() => WMTPACUtils.parseQRCode("eyJ0eXAiOiJKV1QiLCJhbGciOiJub25lIn0.1eyJvaWQiOiJMRG5JY0NjR.GhjRHdHNVNLejhLeWdQeG9PbXh3dHpJc29zMEUrSFBYUHlvIiwicG90cCI6IjU4NTkwMDU5In0====="), throwsA(isA<WMTException>()));
    });

    test("testDeeplinkPACParserWithInvalidURL", () {
      expect(() => WMTPACUtils.parseDeeplink("scheme://an-invalid-url.com"), throwsA(isA<WMTException>()));
    });

    test("testDeeplinkParserWithValidURLButInvalidQuery", () {
      expect(() => WMTPACUtils.parseDeeplink("scheme://operation?code=abc"), throwsA(isA<WMTException>()));
    });

    test("testDeeplinkPACParserWithValidJWTCode", () {
      final parsed = WMTPACUtils.parseDeeplink("scheme://operation?code=eyJhbGciOiJub25lIiwidHlwZSI6IkpXVCJ9.eyJvaWQiOiIzYjllZGZkMi00ZDgyLTQ3N2MtYjRiMy0yMGZhNWM5OWM5OTMiLCJwb3RwIjoiMTQzNTc0NTgifQ==");
      expect(parsed.potp, "14357458");
      expect(parsed.oid, "3b9edfd2-4d82-477c-b4b3-20fa5c99c993");
    });

    test("testDeeplinkParserWithValidPACCode", () {
      final parsed = WMTPACUtils.parseDeeplink("scheme://operation?oid=df6128fc-ca51-44b7-befa-ca0e1408aa63&potp=56725494");
      expect(parsed.potp, "56725494");
      expect(parsed.oid, "df6128fc-ca51-44b7-befa-ca0e1408aa63");
    });

    test("testDeeplinkPACParserWithValidAnonymousDeeplinkQRCode", () {
      final parsed = WMTPACUtils.parseQRCode("scheme://operation?oid=df6128fc-ca51-44b7-befa-ca0e1408aa63");
      expect(parsed.potp, isNull);
      expect(parsed.oid, "df6128fc-ca51-44b7-befa-ca0e1408aa63");
    });

    test("testDeeplinkPACParserWithAnonymousJWTQRCodeWithOnlyOperationId", () {
      final parsed = WMTPACUtils.parseQRCode("eyJhbGciOiJub25lIiwidHlwZSI6IkpXVCJ9.eyJvaWQiOiI1YWM0YjNlOC05MjZmLTQ1ZjAtYWUyOC1kMWJjN2U2YjA0OTYifQ==");
      expect(parsed.potp, isNull);
      expect(parsed.oid, "5ac4b3e8-926f-45f0-ae28-d1bc7e6b0496");
    });
  });
}
