// Shared declarations are test fixtures, not package API.
// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

@immutable
final class TestRoute implements RouteNode {
  const TestRoute(this.name, {this.pageKeyError});

  @override
  final String name;
  final Error? pageKeyError;

  @override
  List<RouteNode> get children => const [];

  @override
  LocalKey get pageKey {
    final error = pageKeyError;
    if (error != null) {
      throw error;
    }
    return ValueKey<String>(name);
  }

  @override
  Map<String, String> toParams() => const {};

  @override
  RouteNode withChildren(List<RouteNode> children) => this;

  @override
  bool operator ==(Object other) => other is TestRoute && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

final class ThrowingRouteList extends ListBase<TestRoute> {
  ThrowingRouteList(this.error);

  final Error error;

  @override
  int get length => 1;

  @override
  set length(int value) => throw UnsupportedError('read only');

  @override
  TestRoute operator [](int index) => throw error;

  @override
  void operator []=(int index, TestRoute value) =>
      throw UnsupportedError('read only');
}

final class OpaqueRouteState {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls++;
    return 'secret route-information state';
  }
}

Page<Object?> testPage(BuildContext context, TestRoute route) =>
    MaterialPage<Object?>(key: route.pageKey, child: Text(route.name));

final class TestParser extends RouteInformationParser<List<TestRoute>> {
  const TestParser();

  @override
  Future<List<TestRoute>> parseRouteInformation(RouteInformation information) =>
      SynchronousFuture<List<TestRoute>>(<TestRoute>[
        TestRoute(
          information.uri.pathSegments.isEmpty
              ? 'home'
              : information.uri.pathSegments.last,
        ),
      ]);

  @override
  RouteInformation restoreRouteInformation(List<TestRoute> configuration) =>
      RouteInformation(uri: Uri(path: '/${configuration.last.name}'));
}

final class ControlledParser extends RouteInformationParser<List<TestRoute>> {
  final Map<String, Completer<List<TestRoute>>> pending =
      <String, Completer<List<TestRoute>>>{};
  final List<RouteInformation> received = <RouteInformation>[];

  @override
  Future<List<TestRoute>> parseRouteInformation(RouteInformation information) {
    received.add(information);
    final name = information.uri.pathSegments.last;
    return (pending[name] ??= Completer<List<TestRoute>>()).future;
  }

  @override
  RouteInformation restoreRouteInformation(List<TestRoute> configuration) =>
      RouteInformation(uri: Uri(path: '/${configuration.last.name}'));
}

final class StatePreservingParser
    extends RouteInformationParser<List<TestRoute>> {
  Object? lastState;
  RouteInformation? lastInput;

  @override
  Future<List<TestRoute>> parseRouteInformation(RouteInformation information) {
    lastInput = information;
    lastState = information.state;
    return SynchronousFuture<List<TestRoute>>(<TestRoute>[
      TestRoute(information.uri.pathSegments.last),
    ]);
  }

  @override
  RouteInformation restoreRouteInformation(List<TestRoute> configuration) =>
      RouteInformation(
        uri: Uri(
          path: '/${configuration.single.name}',
          queryParameters: const <String, String>{'q': '1'},
          fragment: 'section',
        ),
        state: lastState,
      );
}

final class ParserDependency extends InheritedWidget {
  const ParserDependency({
    required this.value,
    required super.child,
    super.key,
  });

  final String value;

  static String of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ParserDependency>()!.value;

  @override
  bool updateShouldNotify(ParserDependency oldWidget) =>
      value != oldWidget.value;
}

final class DependencyParser extends RouteInformationParser<List<TestRoute>> {
  String? dependency;

  @override
  Future<List<TestRoute>> parseRouteInformationWithDependencies(
    RouteInformation routeInformation,
    BuildContext context,
  ) {
    dependency = ParserDependency.of(context);
    return SynchronousFuture<List<TestRoute>>(const [TestRoute('home')]);
  }

  @override
  RouteInformation restoreRouteInformation(List<TestRoute> configuration) =>
      RouteInformation(uri: Uri(path: '/home'));
}

final class RecordingProvider extends RouteInformationProvider
    with ChangeNotifier {
  RecordingProvider(String path)
    : _value = RouteInformation(uri: Uri(path: path));

  RouteInformation _value;
  final List<
    ({RouteInformation information, RouteInformationReportingType type})
  >
  reports =
      <
        ({
          RouteInformation information,
          RouteInformationReportingType type,
        })
      >[];
  bool disposed = false;

  @override
  RouteInformation get value => _value;

  void go(RouteInformation information) {
    _value = information;
    notifyListeners();
  }

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    reports.add((information: routeInformation, type: type));
    _value = routeInformation;
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

final class ThrowingListenerProvider extends RouteInformationProvider {
  ThrowingListenerProvider(this.error);

  final Error error;
  final List<VoidCallback> listeners = <VoidCallback>[];

  @override
  RouteInformation get value => RouteInformation(uri: Uri(path: '/home'));

  @override
  void addListener(VoidCallback listener) {
    listeners.add(listener);
    throw error;
  }

  @override
  void removeListener(VoidCallback listener) => listeners.remove(listener);

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {}
}

RoutingConfig<TestRoute> createTestConfig(
  RoutesState<TestRoute> state, {
  RouteInformationParser<List<TestRoute>> parser = const TestParser(),
  RouteInformationProvider? provider,
}) => RoutingConfig<TestRoute>(
  state: state,
  routeInformationParser: parser,
  routeInformationProvider: provider,
  pageBuilder: testPage,
);

Future<({Object error, StackTrace stackTrace})> captureError(
  Future<Object> future,
) async {
  try {
    await future;
  } on Object catch (error, stackTrace) {
    return (error: error, stackTrace: stackTrace);
  }
  fail('Expected the Future to fail.');
}
