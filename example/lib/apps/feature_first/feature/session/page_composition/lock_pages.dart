import '../view/unlock_screen.dart';
import '../../../composition/app_route_page_catalog.dart';
import 'package:rolter/rolter.dart';

import '../routing/lock_route.dart';

/// Session-lock feature page contribution.
final AppRoutePageDefinition lockPageDefinition =
    TypedAppRoutePageDefinition<LockRoute>(
      pageFactory: (context, route, nestedPageBuilder) => NoAnimationPage(
        key: route.pageKey,
        name: route.name,
        child: const UnlockScreen(),
      ),
    );
