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
  Page<Object?> buildPage(BuildContext context) => const MaterialPage(
    key: ValueKey<String>('home'),
    child: Scaffold(body: Center(child: Text('Rolter consumer smoke'))),
  );

  @override
  Map<String, String> toParams() => const {};

  @override
  RouteNode withChildren(List<RouteNode> children) => this;
}

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
        routerDelegate: RoutingDelegate<SmokeRoute>(state),
        routeInformationParser: RoutingInformationParser<SmokeRoute>(
          TreeUrlCodec<SmokeRoute>(registry),
        ),
      ),
    ),
  );
}
