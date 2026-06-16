import 'package:example/feature/confirm/routing/confirm_route.dart';
import 'package:example/core/routing/app_navigator.dart';

/// Confirm feature navigation sugar, added to the shared [AppNavigator].
extension ConfirmNav on AppNavigator {
  Future<bool?> confirm(String message) =>
      pushForResult<bool>(ConfirmRoute(message));
}
