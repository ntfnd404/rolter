import 'home_route.dart';
import '../../../core/routing/app_navigator.dart';

/// Home feature's navigation sugar, added to the shared [AppNavigator].
extension HomeNav on AppNavigator {
  void toHome() => clearAndPush(const HomeRoute());
}
