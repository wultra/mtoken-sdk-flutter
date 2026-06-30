import 'package:flutter_test/flutter_test.dart';
import 'package:mtoken_sdk_flutter/src/operations/mobile_token_data.dart';
import 'package:mtoken_sdk_flutter/src/operations/pre_approval_screens_recorder.dart';

void main() {
  group('WMTMobileTokenDataBuilder', () {
    test('builds empty map', () {
      final builder = WMTMobileTokenDataBuilder();
      final result = builder.build();
      expect(result, isEmpty);
    });

    test('puts and retrieves generic entries', () {
      final builder = WMTMobileTokenDataBuilder();
      builder.put('key1', 'value1');
      builder.put('key2', 42);
      builder.put('key3', true);

      final result = builder.build();
      expect(result['key1'], 'value1');
      expect(result['key2'], 42);
      expect(result['key3'], true);
    });

    test('initialData is included in build', () {
      final builder = WMTMobileTokenDataBuilder({'initial': 'data'});
      builder.put('extra', 'value');

      final result = builder.build();
      expect(result['initial'], 'data');
      expect(result['extra'], 'value');
    });

    test('put replaces existing key', () {
      final builder = WMTMobileTokenDataBuilder();
      builder.put('key', 'first');
      builder.put('key', 'second');

      final result = builder.build();
      expect(result['key'], 'second');
    });

    test('putRecord adds record by key', () {
      final builder = WMTMobileTokenDataBuilder();
      builder.putRecord(_TestRecord('testKey', 'testValue'));

      final result = builder.build();
      expect(result['testKey'], 'testValue');
    });

    test('putRecord replaces record with same key', () {
      final builder = WMTMobileTokenDataBuilder();
      builder.putRecord(_TestRecord('key', 'first'));
      builder.putRecord(_TestRecord('key', 'second'));

      final result = builder.build();
      expect(result['key'], 'second');
    });

    test('remove removes generic entry', () {
      final builder = WMTMobileTokenDataBuilder();
      builder.put('key', 'value');

      expect(builder.remove('key'), true);
      expect(builder.build(), isEmpty);
    });

    test('remove removes record', () {
      final builder = WMTMobileTokenDataBuilder();
      builder.putRecord(_TestRecord('key', 'value'));

      expect(builder.remove('key'), true);
      expect(builder.build(), isEmpty);
    });

    test('remove returns false for missing key', () {
      final builder = WMTMobileTokenDataBuilder();
      expect(builder.remove('nonexistent'), false);
    });

    test('remove returns true for key with null value', () {
      final builder = WMTMobileTokenDataBuilder();
      builder.put('key', null);

      expect(builder.remove('key'), true);
      expect(builder.build(), isEmpty);
    });

    test('clear removes all entries', () {
      final builder = WMTMobileTokenDataBuilder({'init': 'val'});
      builder.put('key1', 'v1');
      builder.putRecord(_TestRecord('key2', 'v2'));
      builder.clear();

      expect(builder.build(), isEmpty);
    });

    test('build returns immutable snapshot', () {
      final builder = WMTMobileTokenDataBuilder();
      builder.put('key', 'value');
      final result = builder.build();

      expect(() => result['new'] = 'fail', throwsA(isA<UnsupportedError>()));
    });

    test('chaining works', () {
      final builder = WMTMobileTokenDataBuilder();
      final result = builder
          .put('a', 1)
          .put('b', 2)
          .putRecord(_TestRecord('c', 3))
          .build();

      expect(result.length, 3);
    });

    test('generic and record can coexist with different keys', () {
      final builder = WMTMobileTokenDataBuilder();
      builder.put('generic', 'gValue');
      builder.putRecord(_TestRecord('record', 'rValue'));

      final result = builder.build();
      expect(result['generic'], 'gValue');
      expect(result['record'], 'rValue');
    });

    test('record value overrides generic with same key', () {
      final builder = WMTMobileTokenDataBuilder();
      builder.put('key', 'genericValue');
      builder.putRecord(_TestRecord('key', 'recordValue'));

      final result = builder.build();
      // Record is applied after generic, so it overrides
      expect(result['key'], 'recordValue');
    });
  });

  group('WMTPreApprovalScreensRecorder', () {
    test('key is preApprovalScreens', () {
      final recorder = WMTPreApprovalScreensRecorder();
      expect(recorder.key, 'preApprovalScreens');
    });

    test('records a single screen visit', () {
      final recorder = WMTPreApprovalScreensRecorder();
      recorder.begin('screen1');
      recorder.end('screen1', WMTPreApprovalScreenAction.continueAction);

      final visits = recorder.build() as List;
      expect(visits.length, 1);
      expect(visits[0]['screen'], 'screen1');
      expect(visits[0]['timestampOpened'], isA<String>());
      expect(visits[0]['timestampClosed'], isA<String>());
      expect(visits[0]['action'], 'CONTINUE');
    });

    test('records multiple screen visits', () {
      final recorder = WMTPreApprovalScreensRecorder();
      recorder.begin('screen1');
      recorder.end('screen1', WMTPreApprovalScreenAction.continueAction);
      recorder.begin('screen2');
      recorder.end('screen2', WMTPreApprovalScreenAction.scan);

      final visits = recorder.build() as List;
      expect(visits.length, 2);
      expect(visits[0]['screen'], 'screen1');
      expect(visits[0]['action'], 'CONTINUE');
      expect(visits[1]['screen'], 'screen2');
      expect(visits[1]['action'], 'SCAN');
    });

    test('appends open visit as-is when switching screens', () {
      final recorder = WMTPreApprovalScreensRecorder();
      recorder.begin('screen1');
      recorder.begin('screen2'); // should append screen1 as-is (no timestampClosed)

      final visits = recorder.build() as List;
      expect(visits.length, 2);

      // screen1 appended without closing (no timestampClosed, no action)
      expect(visits[0]['screen'], 'screen1');
      expect(visits[0].containsKey('timestampClosed'), false);
      expect(visits[0].containsKey('action'), false);

      // screen2 auto-closed by build()
      expect(visits[1]['screen'], 'screen2');
      expect(visits[1]['timestampClosed'], isA<String>());
    });

    test('build auto-closes open visit', () {
      final recorder = WMTPreApprovalScreensRecorder();
      recorder.begin('screen1');

      final visits = recorder.build() as List;
      expect(visits.length, 1);
      expect(visits[0]['screen'], 'screen1');
      expect(visits[0]['timestampClosed'], isA<String>());
      expect(visits[0].containsKey('action'), false);
    });

    test('duplicate begin for same screen is a no-op', () {
      final recorder = WMTPreApprovalScreensRecorder();
      recorder.begin('screen1');
      recorder.begin('screen1'); // duplicate, ignored

      recorder.end('screen1', WMTPreApprovalScreenAction.continueAction);

      final visits = recorder.build() as List;
      expect(visits.length, 1);
    });

    test('end with non-matching id falls back to last unclosed visit', () {
      final recorder = WMTPreApprovalScreensRecorder();
      recorder.begin('screen1');
      recorder.begin('screen2'); // pushes screen1 as-is (unclosed)
      recorder.end('screen1', WMTPreApprovalScreenAction.back); // fallback to screen1 in visits
      recorder.end('screen2', WMTPreApprovalScreenAction.continueAction);

      final visits = recorder.build() as List;
      expect(visits.length, 2);
      expect(visits[0]['screen'], 'screen1');
      expect(visits[0]['action'], 'BACK');
      expect(visits[0]['timestampClosed'], isA<String>());
      expect(visits[1]['screen'], 'screen2');
      expect(visits[1]['action'], 'CONTINUE');
    });

    test('end with non-matching id and no fallback is a no-op', () {
      final recorder = WMTPreApprovalScreensRecorder();
      recorder.begin('screen1');
      recorder.end('screen2', WMTPreApprovalScreenAction.back); // no match, ignored
      recorder.end('screen1', WMTPreApprovalScreenAction.continueAction);

      final visits = recorder.build() as List;
      expect(visits.length, 1);
      expect(visits[0]['action'], 'CONTINUE');
    });

    test('begin with empty id is a no-op', () {
      final recorder = WMTPreApprovalScreensRecorder();
      recorder.begin('');

      final visits = recorder.build() as List;
      expect(visits, isEmpty);
    });

    test('reset clears all visits', () {
      final recorder = WMTPreApprovalScreensRecorder();
      recorder.begin('screen1');
      recorder.end('screen1', WMTPreApprovalScreenAction.continueAction);
      recorder.reset();

      final visits = recorder.build() as List;
      expect(visits, isEmpty);
    });

    test('all action types work', () {
      final recorder = WMTPreApprovalScreensRecorder();

      recorder.begin('s1');
      recorder.end('s1', WMTPreApprovalScreenAction.continueAction);
      recorder.begin('s2');
      recorder.end('s2', WMTPreApprovalScreenAction.back);
      recorder.begin('s3');
      recorder.end('s3', WMTPreApprovalScreenAction.close);
      recorder.begin('s4');
      recorder.end('s4', WMTPreApprovalScreenAction.reject);
      recorder.begin('s5');
      recorder.end('s5', WMTPreApprovalScreenAction.scan);
      recorder.begin('s6');
      recorder.end('s6', WMTPreApprovalScreenAction.custom('CUSTOM_ACTION'));

      final visits = recorder.build() as List;
      expect(visits.length, 6);
      expect(visits[0]['action'], 'CONTINUE');
      expect(visits[1]['action'], 'BACK');
      expect(visits[2]['action'], 'CLOSE');
      expect(visits[3]['action'], 'REJECT');
      expect(visits[4]['action'], 'SCAN');
      expect(visits[5]['action'], 'CUSTOM_ACTION');
    });

    test('chaining works', () {
      final recorder = WMTPreApprovalScreensRecorder();
      recorder
          .begin('s1')
          .end('s1', WMTPreApprovalScreenAction.continueAction)
          .begin('s2')
          .end('s2', WMTPreApprovalScreenAction.scan);

      final visits = recorder.build() as List;
      expect(visits.length, 2);
    });

    test('integrates with builder', () {
      final builder = WMTMobileTokenDataBuilder();
      final recorder = WMTPreApprovalScreensRecorder();

      recorder.begin('screen1');
      recorder.end('screen1', WMTPreApprovalScreenAction.continueAction);

      builder.putRecord(recorder);
      builder.put('customKey', 'customValue');

      final result = builder.build();
      expect(result['customKey'], 'customValue');
      expect(result['preApprovalScreens'], isA<List>());
      expect((result['preApprovalScreens'] as List).length, 1);
      expect((result['preApprovalScreens'] as List)[0]['screen'], 'screen1');
    });

    test('recorder can be reused after reset', () {
      final recorder = WMTPreApprovalScreensRecorder();

      recorder.begin('old');
      recorder.end('old', WMTPreApprovalScreenAction.close);
      recorder.reset();

      recorder.begin('new');
      recorder.end('new', WMTPreApprovalScreenAction.continueAction);

      final visits = recorder.build() as List;
      expect(visits.length, 1);
      expect(visits[0]['screen'], 'new');
    });

    test('timestamps are ISO 8601 strings', () {
      final fixedTime = DateTime.utc(2025, 6, 15, 10, 30, 0);
      final recorder = WMTPreApprovalScreensRecorder(timeProvider: () => fixedTime);

      recorder.begin('screen1');
      recorder.end('screen1', WMTPreApprovalScreenAction.continueAction);

      final visits = recorder.build() as List;
      expect(visits[0]['timestampOpened'], '2025-06-15T10:30:00.000Z');
      expect(visits[0]['timestampClosed'], '2025-06-15T10:30:00.000Z');
    });
  });
}

class _TestRecord implements WMTMobileTokenDataRecord {
  @override
  final String key;
  final dynamic value;

  _TestRecord(this.key, this.value);

  @override
  dynamic build() => value;
}
