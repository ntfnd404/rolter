import 'home_route.dart';
import 'home_route_name.dart';
import '../../../core/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Home feature's decoder contribution to the app registry.
Map<String, RouteDecoder<AppRoute>> get homeRoutes => {
  HomeRouteName.home.wire: (_, _) => const HomeRoute(),
};
