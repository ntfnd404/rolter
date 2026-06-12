import 'package:example/routing/app_route.dart';
import 'package:flutter/widgets.dart';
import 'package:rolter/rolter.dart';

/// The app's navigator. Bare on purpose — each feature adds its own typed sugar
/// via an `extension on AppNavigator` (see `feature/*/*_nav.dart`), so no single
/// file knows every route.
class AppNavigator extends NavigationController<AppRoute> {
  const AppNavigator(super.state);
}

/// Reads the [AppNavigator] from the widget tree.
extension AppNavigatorContext on BuildContext {
  AppNavigator get navigator => NavigatorScope.of<AppNavigator>(this);
}
