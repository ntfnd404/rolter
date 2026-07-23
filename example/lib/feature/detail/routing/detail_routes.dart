import 'detail_route.dart';
import 'detail_route_name.dart';
import '../../../core/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Detail feature decoder contribution to the app registry.
Map<String, RouteDecoder<AppRoute>> get detailRoutes => {
  DetailRouteName.detail.wire: (params, _) =>
      DetailRoute(int.tryParse(params['id'] ?? '') ?? 0),
};
