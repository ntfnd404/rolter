import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

final class SmokeRoute with KeyedRouteEquality {
  const SmokeRoute();

  @override
  List<RouteNode> get children => const [];

  @override
  String get name => 'home';

  @override
  LocalKey get pageKey => const ValueKey<String>('home');

  @override
  Map<String, String> toParams() => const {};

  @override
  RouteNode withChildren(List<RouteNode> children) => this;
}

Page<Object?> buildSmokePage(BuildContext context, SmokeRoute route) =>
    MaterialPage<Object?>(
      key: route.pageKey,
      child: const Scaffold(
        body: Center(child: Text('Rolter consumer smoke')),
      ),
    );

final class OwnedSmokeRoute with KeyedRouteEquality implements PageRouteNode {
  const OwnedSmokeRoute();

  @override
  List<RouteNode> get children => const [];

  @override
  String get name => 'owned';

  @override
  LocalKey get pageKey => const ValueKey<String>('owned');

  @override
  Page<Object?> buildPage(BuildContext context) => MaterialPage<Object?>(
    key: pageKey,
    child: const SizedBox(),
  );

  @override
  Map<String, String> toParams() => const {};

  @override
  RouteNode withChildren(List<RouteNode> children) => this;
}

RoutingDelegate<OwnedSmokeRoute> createOwnedDelegate(
  RoutesState<OwnedSmokeRoute> state,
) => RoutingDelegate<OwnedSmokeRoute>(
  state,
  pageBuilder: buildPageFromRouteNode<OwnedSmokeRoute>,
);

NavigationQueue<SmokeRoute> createQueue(
  SnapshotProcessor<SmokeRoute> processor,
) => NavigationQueue<SmokeRoute>(processor);

void main() {
  Future<void> processSnapshot(List<SmokeRoute> _) async {}

  final customQueue = createQueue(processSnapshot);
  customQueue.add(const [SmokeRoute()]);

  final registry = RouteRegistry<SmokeRoute>(
    {'home': (params, children) => const SmokeRoute()},
    fallback: (uri) => const SmokeRoute(),
  );
  final state = RoutesState<SmokeRoute>(
    const [SmokeRoute()],
    (requested) => requested,
  );
  final controller = NavigationController<SmokeRoute>(state);
  runApp(
    NavigatorScope<NavigationController<SmokeRoute>>(
      navigator: controller,
      child: MaterialApp.router(
        routerDelegate: RoutingDelegate<SmokeRoute>(
          state,
          pageBuilder: buildSmokePage,
        ),
        routeInformationParser: RoutingInformationParser<SmokeRoute>(
          TreeUrlCodec<SmokeRoute>(registry),
          routesForRootPath: (_) => const <SmokeRoute>[SmokeRoute()],
        ),
      ),
    ),
  );
}
