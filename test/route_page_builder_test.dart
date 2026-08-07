import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

final class _DataOnlyRoute implements RouteNode {
  const _DataOnlyRoute();

  @override
  List<RouteNode> get children => const [];

  @override
  String get name => 'data-only';

  @override
  LocalKey get pageKey => const ValueKey('data-only');

  @override
  Map<String, String> toParams() => const {};

  @override
  RouteNode withChildren(List<RouteNode> children) => this;
}

final class _OwnedRoute implements PageRouteNode {
  const _OwnedRoute(this.onBuild);

  final Page<Object?> Function(BuildContext context, _OwnedRoute route) onBuild;

  @override
  List<RouteNode> get children => const [];

  @override
  String get name => 'owned';

  @override
  LocalKey get pageKey => const ValueKey('owned');

  @override
  Page<Object?> buildPage(BuildContext context) => onBuild(context, this);

  @override
  Map<String, String> toParams() => const {};

  @override
  RouteNode withChildren(List<RouteNode> children) => this;
}

void main() {
  test('RouteNode supports a data-only implementation', () {
    const route = _DataOnlyRoute();

    expect(route.name, 'data-only');
    expect(route.children, isEmpty);
  });

  testWidgets('route-owned adapter forwards context, route, and page', (
    tester,
  ) async {
    late BuildContext adapterContext;
    late BuildContext ownedContext;
    late _OwnedRoute ownedRoute;
    late Page<Object?> actualPage;
    const expectedPage = MaterialPage<Object?>(
      key: ValueKey('owned'),
      child: SizedBox(),
    );
    late final _OwnedRoute route;
    route = _OwnedRoute((context, receivedRoute) {
      ownedContext = context;
      ownedRoute = receivedRoute;

      return expectedPage;
    });

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          adapterContext = context;
          actualPage = buildPageFromRouteNode<_OwnedRoute>(context, route);

          return const SizedBox();
        },
      ),
    );

    expect(ownedContext, same(adapterContext));
    expect(ownedRoute, same(route));
    expect(actualPage, same(expectedPage));
  });
}
