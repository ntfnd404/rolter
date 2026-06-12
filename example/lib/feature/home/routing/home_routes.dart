import 'package:example/feature/home/routing/animated_route.dart';
import 'package:example/feature/home/routing/detail_route.dart';
import 'package:example/feature/home/routing/home_route.dart';
import 'package:example/feature/home/routing/home_route_name.dart';
import 'package:example/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Home feature's decoder contribution to the app registry.
Map<String, RouteDecoder<AppRoute>> get homeRoutes => {
  HomeRouteName.home.wire: (_, _) => const HomeRoute(),
  HomeRouteName.detail.wire: (params, _) =>
      DetailRoute(int.tryParse(params['id'] ?? '') ?? 0),
  HomeRouteName.animated.wire: (_, _) => const AnimatedRoute(),
};
