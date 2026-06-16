import 'package:example/feature/detail/routing/detail_route.dart';
import 'package:example/core/routing/app_navigator.dart';

/// Detail feature navigation sugar, added to the shared [AppNavigator].
extension DetailNav on AppNavigator {
  void toDetail(int id) => push(DetailRoute(id));
}
