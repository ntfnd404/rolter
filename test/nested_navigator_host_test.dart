import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

/// A leaf rendered inside the nested navigator, with an AppBar so a back button
/// appears when the inner stack can pop.
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

  @override
  Page<Object?> buildPage(BuildContext context) => MaterialPage(
    key: pageKey,
    child: Scaffold(
      appBar: AppBar(title: Text('$name-title')),
      body: Center(child: Text('$name-body')),
    ),
  );
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
  Page<Object?> buildPage(BuildContext context) => MaterialPage(
    key: pageKey,
    child: NestedNavigatorHost<RouteNode>(
      service: NavigatorScope.of<NavigationController<RouteNode>>(context),
      path: const ['shell'],
    ),
  );

  @override
  int get hashCode => Object.hashAll(children);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Shell && listEquals(other.children, children);
}

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
    final delegate = RoutingDelegate<RouteNode>(state);
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
}
