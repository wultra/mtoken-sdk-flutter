import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtoken_sdk_flutter/mtoken_sdk_flutter.dart';

void main() {

  group("deserializationTests", () {
    test('testRealDataNoAttributes', () {
      
      final json = '{ "status": "OK", "responseObject": [ { "id": "8eebd926-40d4-4214-8208-307f01b0b68f", "status": "APPROVED", "name": "authorize_payment", "data": "A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017", "operationCreated": "2018-06-21T13:41:41+0000", "operationExpires": "2018-06-21T13:46:45+0000", "allowedSignatureType": { "type": "2FA", "variants": [ "possession_knowledge", "possession_biometry" ] }, "formData": { "title": "Confirm Payment", "message": "Hello,\\nplease confirm following payment:", "attributes": [ ] } } ] }';
      final list = getList(json);
      expect(list.length, 1);
      final operation = list[0];
      expect(operation.id, "8eebd926-40d4-4214-8208-307f01b0b68f");
      expect(operation.status, WMTUserOperationStatus.approved);
      expect(operation.name, "authorize_payment");
      expect(operation.data, "A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017");
      expect(operation.operationCreated, DateTime.parse("2018-06-21T13:41:41+0000"));
      expect(operation.operationExpires, DateTime.parse("2018-06-21T13:46:45+0000"));
      expect(operation.allowedSignatureType.type, WMTSignatureType.twoFactor);
      expect(operation.allowedSignatureType.variants.length, 2);
      expect(operation.allowedSignatureType.variants[0], WMTSignatureVariant.possessionKnowledge);
      expect(operation.allowedSignatureType.variants[1], WMTSignatureVariant.possessionBiometry);
      expect(operation.formData.title, "Confirm Payment");
      expect(operation.formData.message, "Hello,\nplease confirm following payment:");
      expect(operation.formData.attributes, isEmpty);
    });

    test('testRealDataWithAttributes', () {
      final json = '{ "status": "OK", "responseObject": [ { "id": "8eebd926-40d4-4214-8208-307f01b0b68f", "status": "APPROVED", "name": "authorize_payment", "data": "A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017", "operationCreated": "2018-06-21T13:41:41+0000", "operationExpires": "2018-06-21T13:46:45+0000", "allowedSignatureType": { "type": "2FA", "variants": [ "possession_knowledge", "possession_biometry" ] }, "formData": { "title": "Confirm Payment", "message": "Hello,\\nplease confirm following payment:", "attributes": [ { "type": "AMOUNT", "id": "operation.amount", "label": "Amount", "amount": 100, "currency": "CZK" }, { "type": "KEY_VALUE", "id": "operation.account", "label": "To Account", "value": "238400856/0300" }, { "type": "KEY_VALUE", "id": "operation.dueDate", "label": "Due Date", "value": "Jun 29, 2017" }, { "type": "NOTE", "id": "operation.note", "label": "Note", "note": "Utility Bill Payment - 05/2017" } ] } } ] }';
      final list = getList(json);
      expect(list.length, 1);
      final operation = list[0];
      expect(operation.formData.attributes.length, 4);
      final amountAttribute = operation.formData.attributes[0] as WMTOperationAttributeAmount;
      expect(amountAttribute.id, "operation.amount");
      expect(amountAttribute.label, "Amount");
      expect(amountAttribute.amount, 100);
      expect(amountAttribute.currency, "CZK");
      final keyAttribute = operation.formData.attributes[1] as WMTOperationAttributeKeyValue;
      expect(keyAttribute.id, "operation.account");
      expect(keyAttribute.label, "To Account");
      expect(keyAttribute.value, "238400856/0300");
      final dateAttribute = operation.formData.attributes[2] as WMTOperationAttributeKeyValue;
      expect(dateAttribute.id, "operation.dueDate");
      expect(dateAttribute.label, "Due Date");
      expect(dateAttribute.value, "Jun 29, 2017");
      final noteAttribute = operation.formData.attributes[3] as WMTOperationAttributeNote;
      expect(noteAttribute.id, "operation.note");
      expect(noteAttribute.label, "Note");
      expect(noteAttribute.note, "Utility Bill Payment - 05/2017");
    });

    test('testRealDataWithAttributes2', () {
      final json = '{"status":"OK","currentTimestamp":"2023-02-10T12:30:42+0000","responseObject":[{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3", "status": "APPROVED","name":"authorize_payment","data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017","operationCreated":"2018-08-08T12:30:42+0000","operationExpires":"2018-08-08T12:35:43+0000","allowedSignatureType":{"type":"2FA","variants":["possession_knowledge", "possession_biometry"]},"formData":{"title":"Potvrzení platby","message":"Dobrý den,prosíme o potvrzení následující platby:","attributes":[{"type":"AMOUNT","id":"operation.amount","label":"Částka","amount":965165234082.23,"currency":"CZK","valueFormatted": "965165234082.23 CZK"},{"type":"KEY_VALUE","id":"operation.account","label":"Na účet","value":"238400856/0300"},{"type":"KEY_VALUE","id":"operation.dueDate","label":"Datum splatnosti","value":"29.6.2017"},{"type":"NOTE","id":"operation.note","label":"Poznámka","note":"Utility Bill Payment - 05/2017"},{"type":"PARTY_INFO","id":"operation.partyInfo","label":"Application","partyInfo":{"logoUrl":"http://whywander.com/wp-content/uploads/2017/05/prague_hero-100x100.jpg","name":"Tesco","description":"Objevte více příběhů psaných s chutí","websiteUrl":"https://itesco.cz/hello/vse-o-jidle/pribehy-psane-s-chuti/clanek/tomovy-burgery-pro-zapalene-fanousky/15012"}},{ "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmount": 1.26, "sourceCurrency": "ETC", "sourceAmountFormatted": "1.26", "sourceCurrencyFormatted": "ETC", "sourceValueFormatted": "1.26 ETC", "targetAmount": 1710.98, "targetCurrency": "USD", "targetAmountFormatted": "1,710.98", "targetCurrencyFormatted": "USD", "targetValueFormatted": "1,710.98 USD"},{ "type": "IMAGE", "id": "operation.image", "label": "Image", "thumbnailUrl": "https://example.com/123_thumb.jpeg", "originalUrl": "https://example.com/123.jpeg" },{ "type": "IMAGE", "id": "operation.image", "label": "Image", "thumbnailUrl": "https://example.com/123_thumb.jpeg" }]}},{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3","name":"authorize_payment","status": "APPROVED","data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017","operationCreated":"2018-08-08T12:30:42+0000","operationExpires":"2018-08-08T12:35:43+0000","allowedSignatureType":{"type":"1FA","variants":["possession_knowledge"]},"formData":{"title":"Potvrzení platby","message":"Dobrý den,prosíme o potvrzení následující platby:","attributes":[{"type":"AMOUNT","id":"operation.amount","label":"Částka","amount":100,"currency":"CZK"},{"type":"KEY_VALUE","id":"operation.account","label":"Na účet","value":"238400856/0300"},{"type":"KEY_VALUE","id":"operation.dueDate","label":"Datum splatnosti","value":"29.6.2017"},{"type":"NOTE","id":"operation.note","label":"Poznámka","note":"Utility Bill Payment - 05/2017"}]}}]}';
      final list = getList(json);
      expect(list.length, 2);
      final operation = list[0];
      expect(operation.formData.attributes.length, 8);

      final amountAttribute = operation.formData.attributes[0] as WMTOperationAttributeAmount;
      expect(amountAttribute.id, "operation.amount");
      expect(amountAttribute.label, "Částka");
      expect(amountAttribute.amount, 965165234082.23);
      expect(amountAttribute.currency, "CZK");
      expect(amountAttribute.valueFormatted, "965165234082.23 CZK");
      expect(amountAttribute.amountFormatted, isNull);
      expect(amountAttribute.currencyFormatted, isNull);

      final keyAttribute = operation.formData.attributes[1] as WMTOperationAttributeKeyValue;
      expect(keyAttribute.id, "operation.account");
      expect(keyAttribute.label, "Na účet");
      expect(keyAttribute.value, "238400856/0300");

      final dateAttribute = operation.formData.attributes[2] as WMTOperationAttributeKeyValue;
      expect(dateAttribute.id, "operation.dueDate");
      expect(dateAttribute.label, "Datum splatnosti");
      expect(dateAttribute.value, "29.6.2017");

      final noteAttribute = operation.formData.attributes[3] as WMTOperationAttributeNote;
      expect(noteAttribute.id, "operation.note");
      expect(noteAttribute.label, "Poznámka");
      expect(noteAttribute.note, "Utility Bill Payment - 05/2017");

      // unsupported PARTY_INFO attribute
      final partyInfoAttribute = operation.formData.attributes[4];
      expect(partyInfoAttribute.type, WMTAttributeType.unknown);
      expect(partyInfoAttribute.id, "operation.partyInfo");
      expect(partyInfoAttribute.label, "Application");

      final conversionAttribute = operation.formData.attributes[5] as WMTOperationAttributeAmountConversion;
      expect(conversionAttribute.id, "operation.conversion");
      expect(conversionAttribute.label, "Conversion");
      expect(conversionAttribute.isDynamic, isTrue);
      expect(conversionAttribute.sourceAmount, 1.26);
      expect(conversionAttribute.sourceCurrency, "ETC");
      expect(conversionAttribute.sourceAmountFormatted, "1.26");
      expect(conversionAttribute.sourceCurrencyFormatted, "ETC");
      expect(conversionAttribute.sourceValueFormatted, "1.26 ETC");
      expect(conversionAttribute.targetAmount, 1710.98);
      expect(conversionAttribute.targetCurrency, "USD");
      expect(conversionAttribute.targetAmountFormatted, "1,710.98");
      expect(conversionAttribute.targetCurrencyFormatted, "USD");
      expect(conversionAttribute.targetValueFormatted, "1,710.98 USD");

      final imageAttribute1 = operation.formData.attributes[6] as WMTOperationAttributeImage;
      expect(imageAttribute1.id, "operation.image");
      expect(imageAttribute1.label, "Image");
      expect(imageAttribute1.thumbnailUrl, "https://example.com/123_thumb.jpeg");
      expect(imageAttribute1.originalUrl, "https://example.com/123.jpeg");

      final imageAttribute2 = operation.formData.attributes[7] as WMTOperationAttributeImage;
      expect(imageAttribute2.id, "operation.image");
      expect(imageAttribute2.label, "Image");
      expect(imageAttribute2.thumbnailUrl, "https://example.com/123_thumb.jpeg");
      expect(imageAttribute2.originalUrl, isNull);
    });

    test('testAmountConversionAttributesResponseWithOnlyAmountFormattedAndCurrencyFormatted', () {
      final json = '{"status":"OK", "currentTimestamp":"2023-02-10T12:30:42+0000", "responseObject":[{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3", "status": "APPROVED", "name":"authorize_payment", "data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017", "operationCreated":"2018-08-08T12:30:42+0000", "operationExpires":"2018-08-08T12:35:43+0000", "allowedSignatureType": {"type":"2FA", "variants": ["possession_knowledge", "possession_biometry"]}, "formData": {"title":"Potvrzení platby", "message":"Dobrý den,prosíme o potvrzení následující platby:", "attributes": [{"type":"AMOUNT", "id":"operation.amount", "label":"Částka", "amountFormatted":"965165234082.23", "currencyFormatted":"CZK"}, { "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmountFormatted": "1.26", "sourceCurrencyFormatted": "ETC", "targetAmountFormatted": "1710.98", "targetCurrencyFormatted": "USD"}]}}]}';
      final list = getList(json);expect(list.length, 1);
      final operation = list[0];

      final amountAttr = operation.formData.attributes[0] as WMTOperationAttributeAmount;
      expect(amountAttr.id, "operation.amount");
      expect(amountAttr.label, "Částka");
      expect(amountAttr.amount, isNull);
      expect(amountAttr.currency, isNull);
      expect(amountAttr.amountFormatted, "965165234082.23");
      expect(amountAttr.currencyFormatted, "CZK");

      final conversionAttr = operation.formData.attributes[1] as WMTOperationAttributeAmountConversion;
      expect(conversionAttr.id, "operation.conversion");
      expect(conversionAttr.label, "Conversion");
      expect(conversionAttr.isDynamic, isTrue);
      expect(conversionAttr.sourceAmount, isNull);
      expect(conversionAttr.sourceCurrency, isNull);
      expect(conversionAttr.sourceAmountFormatted, "1.26");
      expect(conversionAttr.sourceCurrencyFormatted, "ETC");
      expect(conversionAttr.targetAmount, isNull);
      expect(conversionAttr.targetCurrency, isNull);
      expect(conversionAttr.targetAmountFormatted, "1710.98");
      expect(conversionAttr.targetCurrencyFormatted, "USD");
    });

    test('testUnknownAttribute', () {
      final json = '{"status":"OK","responseObject":[{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3","status": "APPROVED","name":"authorize_payment","data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017","operationCreated":"2018-08-08T12:30:42+0000","operationExpires":"2018-08-08T12:35:43+0000","allowedSignatureType":{"type":"2FA","variants":["possession_knowledge", "possession_biometry"]},"formData":{"title":"Potvrzení platby","message":"Dobrý den,prosíme o potvrzení následující platby:","attributes":[{"type":"THIS_IS_FAKE_ATTR","id":"operation.amount","label":"Částka","amount":965165234082.23,"currency":"CZK","valueFormatted":"965165234082.23 CZK"},{"type":"KEY_VALUE","id":"operation.account","label":"Na účet","value":"238400856/0300"}]}}]}';
      final list = getList(json);
      expect(list.length, 1);
      final operation = list[0];
      expect(operation.formData.attributes.length, 2);
      expect(operation.formData.attributes[0].type, WMTAttributeType.unknown);
    });

    test('testResultTexts', () {
      final json = '{"status":"OK", "currentTimestamp":"2023-02-10T12:30:42+0000", "responseObject":[{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3", "name":"authorize_payment","status": "APPROVED", "data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017", "operationCreated":"2018-08-08T12:30:42+0000", "operationExpires":"2018-08-08T12:35:43+0000", "allowedSignatureType": {"type":"2FA", "variants": ["possession_knowledge", "possession_biometry"]}, "formData": {"title":"Potvrzení platby", "message":"Dobrý den,prosíme o potvrzení následující platby:", "attributes": [{"type":"AMOUNT", "id":"operation.amount", "label":"Částka", "currency":"CZK"}, { "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmount": 1.26, "sourceCurrency": "ETC", "targetAmount": 1710.98, "targetCurrency": "USD"}]}}, {"id":"930febe7-f350-419a-8bc0-c8883e7f71e3", "name":"authorize_payment","status": "APPROVED", "data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017", "operationCreated":"2018-08-08T12:30:42+0000", "operationExpires":"2018-08-08T12:35:43+0000", "allowedSignatureType": {"type":"2FA", "variants": ["possession_knowledge", "possession_biometry"]}, "formData": {"title":"Potvrzení platby", "message":"Dobrý den,prosíme o potvrzení následující platby:", "resultTexts": {"success": "Payment of was confirmed"}, "attributes": [{"type":"AMOUNT", "id":"operation.amount", "label":"Částka", "currency":"CZK"}, { "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmount": 1.26, "sourceCurrency": "ETC", "targetAmount": 1710.98, "targetCurrency": "USD"}]}}, {"id":"930febe7-f350-419a-8bc0-c8883e7f71e3", "name":"authorize_payment","status": "APPROVED", "data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017", "operationCreated":"2018-08-08T12:30:42+0000", "operationExpires":"2018-08-08T12:35:43+0000", "allowedSignatureType": {"type":"2FA", "variants": ["possession_knowledge", "possession_biometry"]}, "formData": {"title":"Potvrzení platby", "message":"Dobrý den,prosíme o potvrzení následující platby:", "resultTexts": {"success": "Payment of was confirmed", "reject": "Payment was rejected", "failure": "Payment approval failed"},"attributes": [{"type":"AMOUNT", "id":"operation.amount", "label":"Částka", "currency":"CZK"}, { "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmount": 1.26, "sourceCurrency": "ETC", "targetAmount": 1710.98, "targetCurrency": "USD"}]}}]}';
      final list = getList(json);

      expect(list.length, 3);

      expect(list[0].formData.resultTexts, isNull);

      final resultText1 = list[1].formData.resultTexts;
      expect(resultText1, isNotNull);
      expect(resultText1!.success, "Payment of was confirmed");
      expect(resultText1.reject, isNull);
      expect(resultText1.failure, isNull);

      final resultText2 = list[2].formData.resultTexts;
      expect(resultText2, isNotNull);
      expect(resultText2!.success, "Payment of was confirmed");
      expect(resultText2.reject, "Payment was rejected");
      expect(resultText2.failure, "Payment approval failed");
    });
  });

  group("pushTests", () {
    test("testPushTokenLegacyApns", () {
      final expectation = jsonDecode("""{"platform":"ios","token":"5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5525"}""");
      final platform = WMTPushPlatform.apns("5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5525", environment: WMTPushApnsEnvironment.development).supportLegacyServer();
      expect(expectation, platform.toRequestObject());
    });

    test("testPushTokenApnsDevelopment", () {
      final expectation = jsonDecode("""{"platform":"apns","token":"5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5526","environment":"development"}""");
      final platform = WMTPushPlatform.apns("5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5526", environment: WMTPushApnsEnvironment.development);
      expect(expectation, platform.toRequestObject());
    });

    test("testPushTokenApnsProduction", () {
      final expectation = jsonDecode("""{"platform":"apns","token":"5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5527","environment":"production"}""");
      final platform = WMTPushPlatform.apns("5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5527", environment: WMTPushApnsEnvironment.production);
      expect(expectation, platform.toRequestObject());
    });

    test("testPushTokenApns", () {
      final expectation = jsonDecode("""{"platform":"apns","token":"5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5528"}""");
      final platform = WMTPushPlatform.apns("5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5528");
      expect(expectation, platform.toRequestObject());
    });

    test("testPushTokenFcm", () {
      final expectation = jsonDecode("""{"platform":"fcm","token":"bk3RNwTe3H0:CI2k_HHwgIpoDKCIZvvDMExUdFQ3P1"}""");
      final platform = WMTPushPlatform.fcm("bk3RNwTe3H0:CI2k_HHwgIpoDKCIZvvDMExUdFQ3P1");
      expect(expectation, platform.toRequestObject());
    });

    test("testPushTokenFcmLegacy", () {
      final expectation = jsonDecode("""{"platform":"android","token":"bk3RNwTe3H0:CI2k_HHwgIpoDKCIZvvDMExUdFQ3P1"}""");
      final platform = WMTPushPlatform.fcm("bk3RNwTe3H0:CI2k_HHwgIpoDKCIZvvDMExUdFQ3P1").supportLegacyServer();
      expect(expectation, platform.toRequestObject());
    });

    test("testPushTokenHms", () {
      final expectation = jsonDecode("""{"platform":"hms","token":"bk3RNwTe3H0:CI2k_HHwgIpoDKCIZvvDMExUdFQ3P1"}""");
      final platform = WMTPushPlatform.hms("bk3RNwTe3H0:CI2k_HHwgIpoDKCIZvvDMExUdFQ3P1");
      expect(expectation, platform.toRequestObject());
    });

    test("testPushTokenHmsLegacy", () {
      final expectation = jsonDecode("""{"platform":"huawei","token":"bk3RNwTe3H0:CI2k_HHwgIpoDKCIZvvDMExUdFQ3P1"}""");
      final platform = WMTPushPlatform.hms("bk3RNwTe3H0:CI2k_HHwgIpoDKCIZvvDMExUdFQ3P1").supportLegacyServer();
      expect(expectation, platform.toRequestObject());
    });
  });

  // TODO: more tests (PACUtils, QRPArser tests)
}

List<WMTUserOperation> getList(String json) {
  final object = jsonDecode(json);
  final list = object['responseObject'] as List<dynamic>;
  return list.map((item) => WMTUserOperation.fromJson(item as Map<String, dynamic>)).toList();
}
