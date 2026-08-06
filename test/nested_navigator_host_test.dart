import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

/// A leaf rendered inside the nested navigator.
@immutable
class _Leaf with KeyedRouteEquality {
  const _Leaf(this.name);

  @override
  final String name;

  @override
  List<RouteNode> get children => const [];

  @override
  LocalKey get pageKey => ValueKey(name);

  @override
  Map<String, String> toParams() => const {};

  @override
  RouteNode withChildren(List<RouteNode> children) => this;
}

/// A shell node whose page hosts a child navigator over its [children].
@immutable
class _Shell implements RouteNode {
  const _Shell(this.children);

  @override
  final List<RouteNode> children;

  @override
  String get name => 'shell';

  @override
  LocalKey get pageKey => const ValueKey('shell');

  @override
  Map<String, String> toParams() => const {};

  @override
  RouteNode withChildren(List<RouteNode> children) => _Shell(children);

  @override
  int get hashCode => Object.hashAll(children);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Shell && listEquals(other.children, children);
}

final class _RecordingBackButtonDispatcher extends BackButtonDispatcher {
  int childrenCreated = 0;
  int childrenForgotten = 0;

  @override
  ChildBackButtonDispatcher createChildBackButtonDispatcher() {
    childrenCreated++;
    return super.createChildBackButtonDispatcher();
  }

  @override
  void forget(ChildBackButtonDispatcher child) {
    childrenForgotten++;
    super.forget(child);
  }
}

Page<Object?> _buildPage(BuildContext context, RouteNode route) =>
    switch (route) {
      _Leaf() => MaterialPage<Object?>(
        key: route.pageKey,
        child: Scaffold(
          appBar: AppBar(title: Text('${route.name}-title')),
          body: Center(child: Text('${route.name}-body')),
        ),
      ),
      _Shell() => MaterialPage<Object?>(
        key: route.pageKey,
        child: NestedNavigatorHost<RouteNode>(
          service: NavigatorScope.of<NavigationController<RouteNode>>(context),
          path: const ['shell'],
          pageBuilder: _buildPage,
        ),
      ),
      _ => throw StateError('Unsupported test route type.'),
    };

void main() {
  testWidgets('a nested back pop mutates the hosted subtree', (tester) async {
    final state = RoutesState<RouteNode>(
      const [
        _Shell([_Leaf('list')]),
      ],
      (stack) => stack,
    );
    addTearDown(state.dispose);
    final controller = NavigationController<RouteNode>(state);
    final delegate = RoutingDelegate<RouteNode>(state, pageBuilder: _buildPage);
    addTearDown(delegate.dispose);

    await tester.pumpWidget(
      NavigatorScope<NavigationController<RouteNode>>(
        navigator: controller,
        child: MaterialApp.router(
          routerDelegate: delegate,
          backButtonDispatcher: RootBackButtonDispatcher(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('list-body'), findsOneWidget);

    // Push a detail into the shell's nested stack.
    controller.mutateAt(
      const ['shell'],
      (node) => node.withChildren([...node.children, const _Leaf('detail')]),
    );
    await state.processingCompleted;
    await tester.pumpAndSettle();

    expect(find.text('detail-body'), findsOneWidget);

    // The inner AppBar back button pops the nested navigator, which must mutate
    // the hosted subtree (not the root stack) via mutateAt + removeNodeByKey.
    await tester.tap(find.byType(BackButton));
    await state.processingCompleted;
    await tester.pumpAndSettle();

    expect(find.text('detail-body'), findsNothing);
    expect(find.text('list-body'), findsOneWidget);
    expect(
      (state.root.single as _Shell).children.map((c) => c.name),
      ['list'],
    );
  });

  testWidgets('nested pages enforce the route/page key contract', (
    tester,
  ) async {
    for (final key in <LocalKey?>[null, const ValueKey('wrong')]) {
      final state = RoutesState<RouteNode>(
        const [
          _Shell([_Leaf('private-child')]),
        ],
        (stack) => stack,
      );
      final controller = NavigationController<RouteNode>(state);
      Page<Object?> invalidNestedBuilder(
        BuildContext context,
        RouteNode route,
      ) => MaterialPage<Object?>(key: key, child: const SizedBox());
      Page<Object?> rootBuilder(BuildContext context, RouteNode route) =>
          MaterialPage<Object?>(
            key: route.pageKey,
            child: NestedNavigatorHost<RouteNode>(
              service: controller,
              path: const ['shell'],
              pageBuilder: invalidNestedBuilder,
            ),
          );
      final delegate = RoutingDelegate<RouteNode>(
        state,
        pageBuilder: rootBuilder,
      );

      await tester.pumpWidget(MaterialApp.router(routerDelegate: delegate));

      final error = tester.takeException();
      expect(error, isA<StateError>());
      expect('$error', contains('does not match RouteNode.pageKey'));
      expect('$error', isNot(contains('private-child')));
      expect('$error', isNot(contains('wrong')));

      await tester.pumpWidget(const SizedBox());
      delegate.dispose();
      state.dispose();
    }
  });

  testWidgets('rejects a child incompatible with the host route type', (
    tester,
  ) async {
    final state = RoutesState<_Shell>(
      const [
        _Shell([_Leaf('leaf')]),
      ],
      (stack) => stack,
    );
    addTearDown(state.dispose);
    final controller = NavigationController<_Shell>(state);
    Page<Object?> builder(BuildContext context, _Shell route) =>
        MaterialPage<Object?>(
          key: route.pageKey,
          child: NestedNavigatorHost<_Shell>(
            service: controller,
            path: const ['shell'],
            pageBuilder: builder,
          ),
        );
    final delegate = RoutingDelegate<_Shell>(state, pageBuilder: builder);
    addTearDown(delegate.dispose);

    await tester.pumpWidget(MaterialApp.router(routerDelegate: delegate));

    final error = tester.takeException();
    expect(error, isA<StateError>());
    expect('$error', contains('incompatible with the host route type'));
    expect('$error', isNot(contains('leaf')));
  });

  testWidgets('nested builder receives exact child instances in order', (
    tester,
  ) async {
    const first = _Leaf('first');
    const second = _Leaf('second');
    final built = <RouteNode>[];
    final state = RoutesState<RouteNode>(
      const [
        _Shell([first, second]),
      ],
      (requested) => requested,
    );
    addTearDown(state.dispose);
    final controller = NavigationController<RouteNode>(state);
    Page<Object?> nestedBuilder(BuildContext context, RouteNode route) {
      built.add(route);
      return MaterialPage<Object?>(
        key: route.pageKey,
        child: Text(route.name),
      );
    }

    Page<Object?> rootBuilder(BuildContext context, RouteNode route) =>
        MaterialPage<Object?>(
          key: route.pageKey,
          child: NestedNavigatorHost<RouteNode>(
            service: controller,
            path: const ['shell'],
            pageBuilder: nestedBuilder,
          ),
        );
    final delegate = RoutingDelegate<RouteNode>(
      state,
      pageBuilder: rootBuilder,
    );
    addTearDown(delegate.dispose);

    await tester.pumpWidget(MaterialApp.router(routerDelegate: delegate));

    expect(built, [same(first), same(second)]);
  });

  testWidgets('nested builder exception is not wrapped', (tester) async {
    final expected = StateError('nested builder failure');
    final expectedStack = StackTrace.current;
    final state = RoutesState<RouteNode>(
      const [
        _Shell([_Leaf('child')]),
      ],
      (requested) => requested,
    );
    addTearDown(state.dispose);
    final controller = NavigationController<RouteNode>(state);
    Page<Object?> rootBuilder(BuildContext context, RouteNode route) =>
        MaterialPage<Object?>(
          key: route.pageKey,
          child: NestedNavigatorHost<RouteNode>(
            service: controller,
            path: const ['shell'],
            pageBuilder: (context, route) => Error.throwWithStackTrace(
              expected,
              expectedStack,
            ),
          ),
        );
    final delegate = RoutingDelegate<RouteNode>(
      state,
      pageBuilder: rootBuilder,
    );
    addTearDown(delegate.dispose);

    await tester.pumpWidget(MaterialApp.router(routerDelegate: delegate));

    expect(tester.takeException(), same(expected));
  });

  testWidgets('releases the child dispatcher when the parent disappears', (
    tester,
  ) async {
    final dispatcher = _RecordingBackButtonDispatcher();
    final state = RoutesState<RouteNode>(
      const [
        _Shell([_Leaf('child')]),
      ],
      (requested) => requested,
    );
    addTearDown(state.dispose);
    final controller = NavigationController<RouteNode>(state);
    Page<Object?> builder(BuildContext context, RouteNode route) =>
        MaterialPage<Object?>(
          key: route.pageKey,
          child: NestedNavigatorHost<RouteNode>(
            service: controller,
            path: const ['shell'],
            pageBuilder: _buildPage,
          ),
        );
    final delegate = RoutingDelegate<RouteNode>(state, pageBuilder: builder);
    addTearDown(delegate.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerDelegate: delegate,
        backButtonDispatcher: dispatcher,
      ),
    );
    expect(dispatcher.childrenCreated, 1);

    await tester.pumpWidget(MaterialApp.router(routerDelegate: delegate));

    expect(dispatcher.childrenForgotten, 1);
  });
}
