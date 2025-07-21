// ignore_for_file: prefer_adjacent_string_concatenation

import 'package:flutter_test/flutter_test.dart';
import 'package:mtoken_sdk_flutter/mtoken_sdk_flutter.dart';

void main() {

  group("qrParserTests", () {
    test("testCurrentFormat", () {
      final code = TestQRData().makeData();

      const expectedSignedDataString = "5ff1b1ed-a3cc-45a3-8ab0-ed60950312b6\n" +
          "Payment\n" +
          "Please confirm this payment\n" +
          "A1*A100CZK*ICZ2730300000001165254011*D20180425*Thello world\n" +
          "BCFX\n" +
          "AD8bOO0Df73kNaIGb3Vmpg==\n" +
          "0";

      final operation = WMTQROperationParser.parse(code);
      expect("5ff1b1ed-a3cc-45a3-8ab0-ed60950312b6", operation.operationId);
      expect("Payment", operation.title);
      expect("Please confirm this payment", operation.message);
      expect(operation.flags.biometricsAllowed, isTrue);
      expect(operation.flags.blockWhenOnCall, isTrue);
      expect(operation.flags.flipButtons, isTrue);
      expect(operation.flags.fraudWarning, isTrue);
      expect("AD8bOO0Df73kNaIGb3Vmpg==", operation.nonce);
      expect("MEYCIQDby1Uq+MaxiAAGzKmE/McHzNOUrvAP2qqGBvSgcdtyjgIhAMo1sgqNa1pPZTFBhhKvCKFLGDuHuTTYexdmHFjUUIJW", operation.signature.signatureString);
      expect(WMTSigningKey.master, operation.signature.signingKey);
      expect(operation.signedData, expectedSignedDataString);

      // Operation data
      expect(WMTQROperationDataVersion.v1, operation.operationData.version);
      expect(1, operation.operationData.templateId);
      expect(4, operation.operationData.fields.length);
      expect("A1*A100CZK*ICZ2730300000001165254011*D20180425*Thello world", operation.operationData.sourceString);

      final fields = operation.operationData.fields;
      final f0 = fields[0] as WMTAmountField;
      expect(f0.type, WMTQROperationDataFieldType.amount);
      expect(100, f0.amount);
      expect("CZK", f0.currency);
      
      final f1 = fields[1] as WMTAccountField;
      expect(f1.type, WMTQROperationDataFieldType.account);
      expect("CZ2730300000001165254011", f1.iban);
      expect(null, f1.bic);
      
      final f2 = fields[2] as WMTDateField;
      expect(f2.type, WMTQROperationDataFieldType.date);
      expect(f2.date.millisecondsSinceEpoch, DateTime(2018, 4, 25).millisecondsSinceEpoch);
      
      final f3 = fields[3] as WMTTextField;
      expect(f3.type, WMTQROperationDataFieldType.text);
      expect(f3.text, "hello world");
    });

    test("testForwardCompatibility", () {
      final qrcode = TestQRData();
      qrcode.operationData = "B2*Xtest";
      qrcode.otherAttrs = ["12345678", "Some Additional Information"];
      qrcode.flags = "B";

      const expectedSignedDataString = 
        "5ff1b1ed-a3cc-45a3-8ab0-ed60950312b6\n" +
        "Payment\n" +
        "Please confirm this payment\n" +
        "B2*Xtest\n" +
        "B\n" +
        "12345678\n" +
        "Some Additional Information\n" +
        "AD8bOO0Df73kNaIGb3Vmpg==\n" +
        "0";

      final operation = WMTQROperationParser.parse(qrcode.makeData());

      expect(operation.isNewerFormat, isTrue);
      expect(operation.signedData, expectedSignedDataString);
      expect(WMTQROperationDataVersion.vX, operation.operationData.version);
      expect(1, operation.operationData.fields.length);
      final f = operation.operationData.fields[0] as WMTFallbackField;
      expect(f.type, WMTQROperationDataFieldType.fallback);
      expect("test", f.text);
    });

    test("testMissingOperationId", () {
      final code = TestQRData();
      code.operationId = "";
      expect(() => WMTQROperationParser.parse(code.makeData()), throwsA(isA<WMTException>()));
    });

    test("testMissingTitleOrMessage", () {
      final code = TestQRData();
      code.title = "";
      code.message = "";
      final operation = WMTQROperationParser.parse(code.makeData());
      expect("", operation.title);
      expect("", operation.message);
    });

    test("testMissingOrBadOperationDataVersion", () {
      for (var data in ["", "A", "2", "A100", "A-100"]) {
          final code = TestQRData();
          code.operationData = data;
          expect(() => WMTQROperationParser.parse(code.makeData()), throwsA(isA<WMTException>()));
      }
    });

    test("testMissingFlags", () {
      final code = TestQRData();
      code.flags = "";
      final operation = WMTQROperationParser.parse(code.makeData());
      expect(operation.flags.biometricsAllowed, isFalse);
      expect(operation.flags.blockWhenOnCall, isFalse);
      expect(operation.flags.flipButtons, isFalse);
      expect(operation.flags.fraudWarning, isFalse);
    });

    test("testMissingOrBadNonce", () {
      for (var nonce in ["", "AAAA", "MEYCIQDby1Uq+MaxiAAGzKmE/McHzNOUrvAP2qqGBvSgcdtyjgIhAMo1sgqNa1pPZTFBhhKvCKFLGDuHuTTYexdmHFjUUIJW"]) {
        final code = TestQRData();
        code.nonce = nonce;
        expect(() => WMTQROperationParser.parse(code.makeData()), throwsA(isA<WMTException>()));
      }
    });

    test("testMissingOrBadSignature", () {
      final code = TestQRData();
      code.signature = "";
      code.signingKey = "";
      expect(() => WMTQROperationParser.parse(code.makeData()), throwsA(isA<WMTException>()));
      
      for (var s in ["", "AAAA", "AD8bOO0Df73kNaIGb3Vmpg=="]) {
        final code = TestQRData();
        code.signature = s;
        expect(() => WMTQROperationParser.parse(code.makeData()), throwsA(isA<WMTException>()));
      }

      for (var sk in ["", "2", "X"]) {
          final code = TestQRData();
          code.signingKey = sk;
          expect(() => WMTQROperationParser.parse(code.makeData()), throwsA(isA<WMTException>()));
      }
    });

    test("testAttributeStringEscaping", () {
      final code = TestQRData();
      code.title = "Hello\\nWorld\\\\xyz";
      code.message = "Hello\\nWorld\\\\xyz\\*";
      final operation = WMTQROperationParser.parse(code.makeData());
      expect("Hello\nWorld\\xyz", operation.title);
      expect("Hello\nWorld\\xyz*", operation.message);
    });

    test("testFieldStringEscaping", () {
      final code = TestQRData();
      code.operationData = "A1*Thello \\* asterisk*Nnew\\nline*Xback\\\\slash";
      final data = code.makeData();
      final operation = WMTQROperationParser.parse(data);

      expect(3, operation.operationData.fields.length);

      final fields = operation.operationData.fields;
      final f0 = fields[0] as WMTTextField;
      expect(f0.type, WMTQROperationDataFieldType.text);
      expect(f0.text, "hello * asterisk");

      final f1 = fields[1] as WMTNoteField;
      expect(f1.type, WMTQROperationDataFieldType.note);
      expect(f1.note, "new\nline");

      final f2 = fields[2] as WMTFallbackField;
      expect(f2.type, WMTQROperationDataFieldType.fallback);
      expect(f2.text, "back\\slash");
    });

    test("testFieldAmount", () {
      final valid = [
        ["A100CZK", double.parse("100"), "CZK"],
        ["A100.00EUR", double.parse("100.00"), "EUR"],
        ["A99.32USD", double.parse("99.32"), "USD"],
        ["A-50000.16GBP", double.parse("-50000.16"), "GBP"],
        ["A.325CZK", double.parse("0.325"), "CZK"]
      ];
      for (var it in valid) {
        final code = TestQRData();
        code.operationData = "A1*${it[0]}";
        final operation = WMTQROperationParser.parse(code.makeData());
        final field = operation.operationData.fields[0] as WMTAmountField;
        expect(field.type, WMTQROperationDataFieldType.amount);
        expect(it[1], field.amount);
        expect(it[2], field.currency);
      }
      // Invalid
      for (var it in ["ACZK", "A", "A0", "AxCZK"]) {
        final code = TestQRData();
        code.operationData = "A1*${it}";
        expect(() => WMTQROperationParser.parse(code.makeData()), throwsA(isA<WMTException>()));
      }
    });

    test("testFieldAccount", () {
      const valid = [
        ["ISOMEIBAN1234,BIC", "SOMEIBAN1234", "BIC"],
        ["ISOMEIBAN", "SOMEIBAN", null],
        ["ISOMEIBAN,", "SOMEIBAN", null]
      ];
      for (var it in valid) {
        final code = TestQRData();
        code.operationData = "A1*${it[0]}";
        final operation = WMTQROperationParser.parse(code.makeData());
        final field = operation.operationData.fields[0] as WMTAccountField;
        expect(field.type, WMTQROperationDataFieldType.account);
        expect(it[1], field.iban);
        expect(it[2], field.bic);
      }
      // Invalid
      for (var field in ["I", "Isomeiban,", "IGOODIBAN,badbic"]) {
        final code = TestQRData();
        code.operationData = "A1*${field}";
        expect(() => WMTQROperationParser.parse(code.makeData()), throwsA(isA<WMTException>()));
      }
    });

    test("testFieldDate", () {
      // Invalid dates
      for (var date in ["D", "D0", "D2004", "D20189999"]) {
        final code = TestQRData();
        code.operationData = "A1*${date}";
        expect(() => WMTQROperationParser.parse(code.makeData()), throwsA(isA<WMTException>()));
      }
    });

    test("testFieldEmpty", () {
      final code = TestQRData();
      code.operationData = "A1*A10CZK****Ttest";
      
      final operation = WMTQROperationParser.parse(code.makeData());
      final fields = operation.operationData.fields;
      expect(5, fields.length);
      expect(fields[0].type, WMTQROperationDataFieldType.amount);
      expect(fields[1].type, WMTQROperationDataFieldType.empty);
      expect(fields[2].type, WMTQROperationDataFieldType.empty);
      expect(fields[3].type, WMTQROperationDataFieldType.empty);
      expect(fields[4].type, WMTQROperationDataFieldType.text);
    });
  });
}

class TestQRData {

  String operationId = "5ff1b1ed-a3cc-45a3-8ab0-ed60950312b6";
  String title = "Payment";
  String message = "Please confirm this payment";
  String operationData = "A1*A100CZK*ICZ2730300000001165254011*D20180425*Thello world";
  String flags = "BCFX";
  List<String>? otherAttrs;
  String nonce = "AD8bOO0Df73kNaIGb3Vmpg==";
  String signingKey = "0";
  String signature = "MEYCIQDby1Uq+MaxiAAGzKmE/McHzNOUrvAP2qqGBvSgcdtyjgIhAMo1sgqNa1pPZTFBhhKvCKFLGDuHuTTYexdmHFjUUIJW";

  String makeData() {
      String attrs = otherAttrs == null ? "" : "${otherAttrs!.join("\n")}\n";
      return "${operationId}\n${title}\n${message}\n${operationData}\n${flags}\n$attrs${nonce}\n${signingKey}${signature}";
  }
}