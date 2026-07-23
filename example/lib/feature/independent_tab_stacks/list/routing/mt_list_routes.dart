import '../../shell/routing/mt_tab.dart';
import 'mt_list_route.dart';
import '../../../../core/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Tab-list decoder contribution to the app registry.
Map<String, RouteDecoder<AppRoute>> get mtListRoutes => {
  'mt-list': (params, _) => MtListRoute(MtTab.fromWire(params['tab'])),
};
