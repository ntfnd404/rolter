import 'package:example/feature/confirm/routing/confirm_route.dart';
import 'package:example/feature/confirm/routing/confirm_route_name.dart';
import 'package:example/core/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Confirm feature decoder contribution to the app registry.
Map<String, RouteDecoder<AppRoute>> get confirmRoutes => {
  ConfirmRouteName.confirm.wire: (params, _) =>
      ConfirmRoute(params['message'] ?? ''),
};
