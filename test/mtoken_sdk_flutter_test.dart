import 'package:flutter_test/flutter_test.dart';

import 'package:mtoken_sdk_flutter/mtoken_sdk_flutter.dart';

void main() {
  test('adds one to input values', () {
    final wmt = WultraMobileToken();
    expect(wmt.addOne(2), 3);
    expect(wmt.addOne(-7), -6);
    expect(wmt.addOne(0), 1);
  });
}
