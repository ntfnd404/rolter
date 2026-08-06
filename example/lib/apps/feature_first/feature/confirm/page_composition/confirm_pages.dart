import '../view/confirm_dialog.dart';
import '../../../navigation/app_navigator.dart';
import '../../../composition/app_route_page_catalog.dart';
import 'package:rolter/rolter.dart';

import '../routing/confirm_route.dart';

/// Confirmation feature page contribution.
final AppRoutePageDefinition confirmPageDefinition =
    TypedAppRoutePageDefinition<ConfirmRoute>(
      pageFactory: (context, route, nestedPageBuilder) => TransparentPage<bool>(
        key: route.pageKey,
        name: route.name,
        child: ConfirmDialog(
          message: route.message,
          onConfirm: () => context.navigator.popWith<bool>(true),
          onCancel: () => context.navigator.popWith<bool>(false),
        ),
      ),
    );
