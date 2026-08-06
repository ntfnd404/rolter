import 'confirm_route.dart';
import '../../../navigation/app_navigator.dart';

/// Confirm feature navigation sugar, added to the shared [AppNavigator].
extension ConfirmNav on AppNavigator {
  Future<bool?> confirm(String message) =>
      pushForResult<bool>(ConfirmRoute(message));
}
