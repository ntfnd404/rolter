import 'lock_route.dart';
import 'session_route_name.dart';
import '../../../core/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Session feature decoder contribution to the app registry.
Map<String, RouteDecoder<AppRoute>> get sessionRoutes => {
      SessionRouteName.lock.wire: (_, unusedChildren) => const LockRoute(),
    };
