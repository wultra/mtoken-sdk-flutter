/*
 * Copyright 2026 Wultra s.r.o.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtoken_sdk_flutter/mtoken_sdk_flutter.dart';
import 'package:mtoken_sdk_flutter/src/networking/networking.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('powerauth_plugin');
  late List<String> events;
  late _Client client;
  late PowerAuth powerAuth;
  late HttpOverrides? previousOverrides;

  setUp(() {
    events = [];
    client = _Client(events);
    powerAuth = PowerAuth('interceptors-test');
    previousOverrides = HttpOverrides.current;
    HttpOverrides.global = _Overrides(client);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          events.add(call.method);
          switch (call.method) {
            case 'getConfiguration':
              return {
                'configuration': 'test',
                'baseEndpointUrl': 'https://test.wultra.com',
              };
            case 'authenticationHeaderForRequestWithBody':
              return {'name': 'X-PowerAuth-Authorization', 'value': 'signed'};
            case 'requestAccessToken':
              return {
                'tokenName': 'possession_universal',
                'tokenIdentifier': 'test-token',
              };
            case 'generateHeaderForToken':
              return {'name': 'X-PowerAuth-Token', 'value': 'token'};
            case 'encryptor_initialize':
              return 'test-encryptor';
            case 'encryptor_encryptRequest':
              return {
                'requestBody': Uint8List.fromList([1, 2, 3]),
                'requestHeaders': [
                  {'name': 'X-PowerAuth-Encryption', 'value': 'encrypted'},
                ],
              };
            case 'encryptor_decryptResponse':
              return Uint8List.fromList(
                utf8.encode(
                  jsonEncode({
                    'status': 'OK',
                    'responseObject': client.responseObject,
                  }),
                ),
              );
            case 'register_releaseNativeObject':
              return null;
            default:
              throw StateError('Unexpected PowerAuth call: ${call.method}');
          }
        });
  });

  tearDown(() {
    HttpOverrides.global = previousOverrides;
    WMTLogger.setLogListener(listener: null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('configuration snapshots and freezes the interceptor list', () {
    final interceptors = <WMTRequestInterceptor>[(headers) {}];
    final config = WMTConfiguration(requestInterceptors: interceptors);
    final original = interceptors.single;
    interceptors.clear();
    expect(config.requestInterceptors, [same(original)]);
    expect(() => config.requestInterceptors.clear(), throwsUnsupportedError);
    expect(
      () => config.requestInterceptors[0] = (_) {},
      throwsUnsupportedError,
    );
  });

  test(
    'runs in order on finalized mutable headers and logs the final values',
    () async {
      final logs = <String>[];
      WMTLogger.setLogListener(
        listener: (message, _) => logs.add(message),
        followVerbosity: false,
      );
      final config = WMTConfiguration(
        acceptLanguage: 'fr',
        userAgent: WMTUserAgent.custom('test-agent'),
        requestInterceptors: [
          (headers) {
            events.add('first');
            expect(headers.value(HttpHeaders.acceptHeader), 'application/json');
            expect(
              headers.value(HttpHeaders.contentTypeHeader),
              'application/json',
            );
            expect(headers.value(HttpHeaders.acceptLanguageHeader), 'fr');
            expect(headers.value(HttpHeaders.userAgentHeader), 'test-agent');
            expect(headers.value('X-PowerAuth-Authorization'), 'signed');
            headers.set('X-Correlation-ID', 'first');
            headers.set(HttpHeaders.acceptLanguageHeader, 'de');
          },
          (headers) {
            events.add('second');
            expect(headers.value('X-Correlation-ID'), 'first');
            expect(headers.value(HttpHeaders.acceptLanguageHeader), 'de');
            headers.set('X-Correlation-ID', 'final');
            headers.set('X-Additional', 'cumulative');
          },
        ],
      );
      final networking = WMTNetworking(
        powerAuth,
        'https://test.wultra.com',
        'test',
        configuration: config,
      );
      // ignore: invalid_use_of_internal_member
      await networking.postSigned(
        {},
        PowerAuthAuthentication.possession(),
        '/signed',
        '/signed',
      );
      expect(
        events,
        containsAllInOrder([
          'authenticationHeaderForRequestWithBody',
          'first',
          'second',
          'add',
          'close',
        ]),
      );
      expect(client.requests.single.headers.value('X-Correlation-ID'), 'final');
      expect(
        client.requests.single.headers.value('X-Additional'),
        'cumulative',
      );
      expect(
        logs.where((message) => message.startsWith('Headers:')).first,
        contains('"x-correlation-id": "final"'),
      );
      expect(client.closed, isTrue);
    },
  );

  test('empty default configuration dispatches requests unchanged', () async {
    final token = await WultraMobileToken.create(powerAuth: powerAuth);
    expect(token.configuration.requestInterceptors, isEmpty);
    // Avoid the platform environment lookup, unrelated to this test.
    token.push.userAgent = WMTUserAgent.custom('plain-agent');
    await token.push.register(WMTPushPlatform.fcm('test'));
    expect(client.requests.single.headers.value('X-PowerAuth-Token'), 'token');
    expect(
      client.requests.single.headers.value(HttpHeaders.acceptLanguageHeader),
      'en',
    );
    expect(client.requests.single.headers.value('X-Correlation-ID'), isNull);
  });

  test(
    'shares interceptors across every service, including encrypted OIDC',
    () async {
      var invocation = 0;
      final config = WMTConfiguration(
        acceptLanguage: 'cs',
        userAgent: WMTUserAgent.custom('shared-agent'),
        requestInterceptors: [
          (headers) {
            invocation++;
            expect(headers.value(HttpHeaders.acceptLanguageHeader), 'cs');
            expect(headers.value(HttpHeaders.userAgentHeader), 'shared-agent');
            if (invocation == 4) {
              expect(events, contains('encryptor_encryptRequest'));
              expect(headers.value('X-PowerAuth-Encryption'), 'encrypted');
            } else {
              expect(headers.value('X-PowerAuth-Token'), 'token');
            }
            headers.set('X-Correlation-ID', 'request-$invocation');
          },
        ],
      );
      final token = await powerAuth.createMobileToken(configuration: config);
      expect(token.configuration, same(config));
      for (final service in <WMTNetworking>[
        token.operations,
        token.push,
        token.inbox,
        token.oidc,
      ]) {
        expect(service.configuration, same(config));
        expect(
          service.configuration.requestInterceptors,
          same(config.requestInterceptors),
        );
      }
      client.responseObject = [];
      await token.operations.getOperations();
      client.responseObject = {};
      await token.push.register(WMTPushPlatform.fcm('test'));
      client.responseObject = {'countUnread': 0};
      await token.inbox.getUnreadCount();
      client.responseObject = {
        'providerId': 'provider',
        'clientId': 'client',
        'scopes': 'openid',
        'authorizeUri': 'https://test.wultra.com/auth',
        'redirectUri': 'test://callback',
        'pkceEnabled': true,
      };
      await token.oidc.getConfig('provider');
      expect(invocation, 4);
      expect(
        client.requests.map(
          (request) => request.headers.value('X-Correlation-ID'),
        ),
        ['request-1', 'request-2', 'request-3', 'request-4'],
      );
      expect(client.requests.last.body, [1, 2, 3]);
      expect(
        events,
        containsAllInOrder([
          'encryptor_encryptRequest',
          'encryptor_decryptResponse',
          'register_releaseNativeObject',
        ]),
      );
    },
  );

  test(
    'interceptor failure prevents dispatch and releases E2EE resources',
    () async {
      final failure = StateError('interceptor failure');
      final token = await powerAuth.createMobileToken(
        configuration: WMTConfiguration(
          userAgent: WMTUserAgent.custom('test-agent'),
          requestInterceptors: [
            (_) => throw failure,
            (_) => fail('Must not run'),
          ],
        ),
      );
      await expectLater(
        token.oidc.getConfig('provider'),
        throwsA(same(failure)),
      );
      expect(events, isNot(contains('close')));
      expect(events, contains('register_releaseNativeObject'));
      expect(client.closed, isTrue);
      expect(client.forceClosed, isTrue);
    },
  );

  test('async interceptor fails the call before dispatch', () async {
    final asyncCompleted = Completer<void>();
    final token = await powerAuth.createMobileToken(
      configuration: WMTConfiguration(
        requestInterceptors: [
          (headers) async {
            await Future<void>.delayed(Duration.zero);
            asyncCompleted.complete();
            throw StateError('late async failure');
          },
          (_) => fail('Must not run'),
        ],
      ),
    );
    token.push.userAgent = WMTUserAgent.custom('test-agent');
    await expectLater(
      token.push.register(WMTPushPlatform.fcm('test')),
      throwsA(
        isA<WMTException>().having(
          (e) => e.description,
          'description',
          contains('synchronous'),
        ),
      ),
    );
    // The late failure of the ignored Future must not escape as an unhandled error.
    await asyncCompleted.future;
    await Future<void>.delayed(Duration.zero);
    expect(events, isNot(contains('add')));
    expect(events, isNot(contains('close')));
    expect(client.forceClosed, isTrue);
  });
}

class _Overrides extends HttpOverrides {
  final _Client client;
  _Overrides(this.client);
  @override
  HttpClient createHttpClient(SecurityContext? context) => client;
}

class _Client extends Fake implements HttpClient {
  final List<String> events;
  final requests = <_Request>[];
  Object responseObject = {};
  bool closed = false;
  bool forceClosed = false;
  _Client(this.events);
  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    final request = _Request(this);
    requests.add(request);
    return request;
  }

  @override
  void close({bool force = false}) {
    closed = true;
    forceClosed = force;
  }
}

class _Request extends Fake implements HttpClientRequest {
  final _Client client;
  @override
  final _Headers headers = _Headers();
  final body = <int>[];
  _Request(this.client);
  @override
  void add(List<int> data) {
    // Real HttpClient requests can freeze headers when the body is added.
    headers.frozen = true;
    body.addAll(data);
    client.events.add('add');
  }

  @override
  Future<HttpClientResponse> close() async {
    client.events.add('close');
    return _Response(
      jsonEncode({'status': 'OK', 'responseObject': client.responseObject}),
    );
  }
}

class _Headers extends Fake implements HttpHeaders {
  final values = <String, List<String>>{};
  bool frozen = false;
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    if (frozen) throw StateError('Headers are no longer mutable');
    values[name.toLowerCase()] = [value.toString()];
  }

  @override
  String? value(String name) => values[name.toLowerCase()]?.single;
  @override
  void forEach(void Function(String name, List<String> values) action) =>
      values.forEach(action);
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  final String body;
  _Response(this.body);
  @override
  int get statusCode => 200;
  @override
  HttpHeaders get headers => _Headers();
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(utf8.encode(body)).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
