import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

  group("operation tests", () {
    setUp(() async {
      
    });

    test("description", () async {
      final password = await PowerAuthPassword.fromString("test");
      expect(password, isNotNull);
    });
  });
}