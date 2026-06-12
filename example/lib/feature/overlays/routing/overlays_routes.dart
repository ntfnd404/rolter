import 'package:example/feature/overlays/routing/confirm_route.dart';
import 'package:example/feature/overlays/routing/overlays_route_name.dart';
import 'package:example/feature/overlays/routing/picker_route.dart';
import 'package:example/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Overlays feature decoder contribution to the app registry.
Map<String, RouteDecoder<AppRoute>> get overlaysRoutes => {
  OverlaysRouteName.picker.wire: (_, _) => const PickerRoute(),
  OverlaysRouteName.confirm.wire: (params, _) =>
      ConfirmRoute(params['message'] ?? ''),
};
