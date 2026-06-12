import 'package:example/feature/session/routing/lock_route.dart';
import 'package:example/feature/session/routing/session_route_name.dart';
import 'package:example/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Session feature decoder contribution to the app registry.
Map<String, RouteDecoder<AppRoute>> get sessionRoutes => {
  SessionRouteName.lock.wire: (_, _) => const LockRoute(),
};
