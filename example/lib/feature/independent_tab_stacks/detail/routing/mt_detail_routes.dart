import '../../shell/routing/mt_tab.dart';
import 'mt_detail_route.dart';
import '../../../../core/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Tab-detail decoder contribution to the app registry.
Map<String, RouteDecoder<AppRoute>> get mtDetailRoutes => {
      'mt-detail': (params, _) => MtDetailRoute(
          MtTab.fromWire(params['tab']), int.parse(params['id']!)),
    };
