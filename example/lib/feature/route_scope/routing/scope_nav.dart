import 'scope_route.dart';
import '../../../core/routing/app_navigator.dart';

/// Scope feature navigation sugar, added to the shared [AppNavigator].
extension ScopeNav on AppNavigator {
  void toScope() => push(const ScopeRoute());
}
