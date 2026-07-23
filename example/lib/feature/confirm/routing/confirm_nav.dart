import 'confirm_route.dart';
import '../../../core/routing/app_navigator.dart';

/// Confirm feature navigation sugar, added to the shared [AppNavigator].
extension ConfirmNav on AppNavigator {
  Future<bool?> confirm(String message) =>
      pushForResult<bool>(ConfirmRoute(message));
}
