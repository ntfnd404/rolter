import 'package:example/feature/animated/routing/animated_route.dart';
import 'package:example/feature/animated/routing/animated_route_name.dart';
import 'package:example/core/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Animated feature decoder contribution to the app registry.
Map<String, RouteDecoder<AppRoute>> get animatedRoutes => {
  AnimatedRouteName.animated.wire: (_, _) => const AnimatedRoute(),
};
