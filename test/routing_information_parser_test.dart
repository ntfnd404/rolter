import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

@immutable
final class _Node implements RouteNode {
  const _Node(this.name, {this.children = const []});

  @override
  final String name;

  @override
  final List<RouteNode> children;

  @override
  LocalKey get pageKey => ValueKey<String>(name);

  @override
  Map<String, String> toParams() => const <String, String>{};

  @override
  RouteNode withChildren(List<RouteNode> children) =>
      _Node(name, children: children);
}

final class _ExcludedNode extends _Node implements HistoryExcluded {
  const _ExcludedNode(super.name);
}

final class _RecordingCodec implements RouteUrlCodec<_Node> {
  _RecordingCodec({this.decoded = const <_Node>[_Node('decoded')]});

  List<_Node> decoded;
  int decodeCalls = 0;
  Object? error;
  StackTrace? errorStack;

  @override
  List<_Node> decode(Uri uri) {
    decodeCalls++;
    final error = this.error;
    if (error != null) {
      Error.throwWithStackTrace(error, errorStack!);
    }
    return decoded;
  }

  @override
  Uri encode(List<_Node> roots) => Uri(path: '/${roots.last.name}');
}

final class _OpaqueState {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls++;
    return 'private-state';
  }
}

Future<({Object error, StackTrace stackTrace})> _captureError(
  Future<Object?> future,
) async {
  try {
    await future;
  } on Object catch (error, stackTrace) {
    return (error: error, stackTrace: stackTrace);
  }
  fail('Expected the Future to fail.');
}

void main() {
  group('RoutingInformationParser root path', () {
    test('resolves empty and slash-only paths before the codec', () async {
      final codec = _RecordingCodec();
      final received = <RouteInformation>[];
      final parser = RoutingInformationParser<_Node>(
        codec,
        routesForRootPath: (information) {
          received.add(information);
          return const <_Node>[_Node('dashboard')];
        },
      );

      final inputs = <RouteInformation>[
        RouteInformation(uri: Uri()),
        RouteInformation(uri: Uri(path: '/')),
        RouteInformation(uri: Uri(path: '//')),
        RouteInformation(uri: Uri(path: '////')),
        RouteInformation(uri: Uri.parse('//example.test?source=authority')),
        RouteInformation(
          uri: Uri(path: '/', query: 'source=news', fragment: 'summary'),
        ),
      ];

      for (final information in inputs) {
        expect(await parser.parseRouteInformation(information), const <_Node>[
          _Node('dashboard'),
        ]);
      }

      expect(received, inputs);
      expect(codec.decodeCalls, 0);
    });

    test('does not mistake an encoded slash segment for the root', () async {
      final codec = _RecordingCodec();
      var rootCalls = 0;
      final parser = RoutingInformationParser<_Node>(
        codec,
        routesForRootPath: (_) {
          rootCalls++;
          return const <_Node>[_Node('dashboard')];
        },
      );

      expect(
        await parser.parseRouteInformation(
          RouteInformation(uri: Uri.parse('/%2F')),
        ),
        const <_Node>[_Node('decoded')],
      );
      expect(rootCalls, 0);
      expect(codec.decodeCalls, 1);
    });

    test(
      'passes query, fragment, and opaque state without stringifying it',
      () async {
        final state = _OpaqueState();
        RouteInformation? received;
        final parser = RoutingInformationParser<_Node>(
          _RecordingCodec(),
          routesForRootPath: (information) {
            received = information;
            return const <_Node>[_Node('dashboard')];
          },
        );
        final information = RouteInformation(
          uri: Uri(path: '/', query: 'tenant=42', fragment: 'section'),
          state: state,
        );

        await parser.parseRouteInformation(information);

        expect(received, same(information));
        expect(received!.uri.query, 'tenant=42');
        expect(received!.uri.fragment, 'section');
        expect(received!.state, same(state));
        expect(state.toStringCalls, 0);
      },
    );

    test('captures the entry query before resolving the root', () async {
      final store = EntryQueryStore();
      var queryWasCaptured = false;
      final parser = RoutingInformationParser<_Node>(
        _RecordingCodec(),
        routesForRootPath: (_) {
          queryWasCaptured = mapEquals(store.value, const {'campaign': 'a'});
          return const <_Node>[_Node('dashboard')];
        },
        entryQuery: store,
      );

      await parser.parseRouteInformation(
        RouteInformation(uri: Uri.parse('/?campaign=a')),
      );

      expect(queryWasCaptured, isTrue);
    });

    test('keeps the captured entry query when root resolution fails', () async {
      final store = EntryQueryStore();
      var notifications = 0;
      store.addListener(() => notifications++);
      final expected = StateError('root failed');
      final parser = RoutingInformationParser<_Node>(
        _RecordingCodec(),
        routesForRootPath: (_) => throw expected,
        entryQuery: store,
      );

      await expectLater(
        parser.parseRouteInformation(
          RouteInformation(uri: Uri.parse('/?campaign=summer%20sale')),
        ),
        throwsA(same(expected)),
      );

      expect(store.value, const <String, String>{
        'campaign': 'summer sale',
      });
      expect(notifications, 1);
    });

    test('copies multiple root pages and nested children', () async {
      final source = <_Node>[
        const _Node('splash'),
        const _Node('shell', children: <RouteNode>[_Node('dashboard')]),
      ];
      final parser = RoutingInformationParser<_Node>(
        _RecordingCodec(),
        routesForRootPath: (_) => source,
      );

      final parsed = await parser.parseRouteInformation(
        RouteInformation(uri: Uri(path: '/')),
      );
      source.add(const _Node('late'));

      expect(parsed.map((node) => node.name), <String>['splash', 'shell']);
      expect(parsed.last.children.single.name, 'dashboard');
      expect(() => parsed.add(const _Node('other')), throwsUnsupportedError);
    });

    test('keeps successful synchronous parsing synchronous', () {
      final parser = RoutingInformationParser<_Node>(
        _RecordingCodec(),
        routesForRootPath: (_) => const <_Node>[_Node('dashboard')],
      );

      expect(
        parser.parseRouteInformation(RouteInformation(uri: Uri(path: '/'))),
        isA<SynchronousFuture<List<_Node>>>(),
      );
    });

    test('rejects an empty root without exposing route information', () async {
      final state = _OpaqueState();
      final parser = RoutingInformationParser<_Node>(
        _RecordingCodec(),
        routesForRootPath: (_) => const <_Node>[],
      );

      final failure = await _captureError(
        parser.parseRouteInformation(
          RouteInformation(
            uri: Uri.parse('/?secret=private-query'),
            state: state,
          ),
        ),
      );

      expect(failure.error, isA<StateError>());
      expect('$failure', isNot(contains('private-query')));
      expect('$failure', isNot(contains('private-state')));
      expect(state.toStringCalls, 0);
    });
  });

  group('RoutingInformationParser errors and restoration', () {
    test('rejects an empty non-root codec result', () async {
      final state = _OpaqueState();
      final parser = RoutingInformationParser<_Node>(
        _RecordingCodec(decoded: const <_Node>[]),
        routesForRootPath: (_) => const <_Node>[_Node('dashboard')],
      );

      final failure = await _captureError(
        parser.parseRouteInformation(
          RouteInformation(
            uri: Uri.parse(
              '/private-location?secret=private-query#private-fragment',
            ),
            state: state,
          ),
        ),
      );

      expect(failure.error, isA<StateError>());
      final diagnostics = '$failure';
      expect(diagnostics, isNot(contains('private-location')));
      expect(diagnostics, isNot(contains('private-query')));
      expect(diagnostics, isNot(contains('private-fragment')));
      expect(diagnostics, isNot(contains('private-state')));
      expect(diagnostics, isNot(contains('_Node')));
      expect(state.toStringCalls, 0);
    });

    test('preserves callback and codec error identity and stack', () async {
      final callbackError = StateError('root failed');
      final callbackStack = StackTrace.current;
      final callbackParser = RoutingInformationParser<_Node>(
        _RecordingCodec(),
        routesForRootPath: (_) => Error.throwWithStackTrace(
          callbackError,
          callbackStack,
        ),
      );

      final callbackFailure = await _captureError(
        callbackParser.parseRouteInformation(
          RouteInformation(uri: Uri(path: '/')),
        ),
      );
      expect(callbackFailure.error, same(callbackError));
      expect(callbackFailure.stackTrace, same(callbackStack));

      final codecError = StateError('codec failed');
      final codecStack = StackTrace.current;
      final codec = _RecordingCodec()
        ..error = codecError
        ..errorStack = codecStack;
      final codecParser = RoutingInformationParser<_Node>(
        codec,
        routesForRootPath: (_) => const <_Node>[_Node('dashboard')],
      );

      final codecFailure = await _captureError(
        codecParser.parseRouteInformation(
          RouteInformation(uri: Uri(path: '/route')),
        ),
      );
      expect(codecFailure.error, same(codecError));
      expect(codecFailure.stackTrace, same(codecStack));
    });

    test('preserves a Base64 decoder FormatException and stack', () async {
      const expected = FormatException('decoder failed');
      final expectedStack = StackTrace.current;
      final registry = RouteRegistry<_Node>(
        {
          'throwing': (params, children) => Error.throwWithStackTrace(
            expected,
            expectedStack,
          ),
        },
        fallback: (uri) => const _Node('fallback'),
      );
      final parser = RoutingInformationParser<_Node>(
        Base64RouteCodec<_Node>(registry),
        routesForRootPath: (_) => const <_Node>[_Node('dashboard')],
      );
      final token = base64Url.encode(
        utf8.encode(
          jsonEncode([
            {'n': 'throwing'},
          ]),
        ),
      );

      final failure = await _captureError(
        parser.parseRouteInformation(
          RouteInformation(uri: Uri(path: '/$token')),
        ),
      );

      expect(failure.error, same(expected));
      expect(failure.stackTrace, same(expectedStack));
    });

    test('rejects restoring an empty configuration', () {
      final parser = RoutingInformationParser<_Node>(
        _RecordingCodec(),
        routesForRootPath: (_) => const <_Node>[_Node('dashboard')],
      );

      expect(
        () => parser.restoreRouteInformation(const <_Node>[]),
        throwsA(isA<StateError>()),
      );
    });

    test('preserves non-empty restoration and HistoryExcluded behavior', () {
      final parser = RoutingInformationParser<_Node>(
        _RecordingCodec(),
        routesForRootPath: (_) => const <_Node>[_Node('dashboard')],
      );

      final restored = parser.restoreRouteInformation(
        const <_Node>[_Node('dashboard')],
      )!;
      expect(restored.uri, Uri(path: '/dashboard'));
      expect(restored.state, isNull);
      expect(
        parser.restoreRouteInformation(
          const <_Node>[_Node('dashboard'), _ExcludedNode('hidden')],
        ),
        isNull,
      );
    });
  });
}
