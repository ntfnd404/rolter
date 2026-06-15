import 'package:example/feature/home/routing/animated_route.dart';
import 'package:example/feature/home/routing/detail_route.dart';
import 'package:example/feature/home/routing/home_route.dart';
import 'package:example/routing/app_navigator.dart';

/// Home feature's navigation sugar, added to the shared [AppNavigator].
extension HomeNav on AppNavigator {
  void toHome() => clearAndPush(const HomeRoute());

  void toDetail(int id) => push(DetailRoute(id));

  void toAnimated() => push(const AnimatedRoute());
}
