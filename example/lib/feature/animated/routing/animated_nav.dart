import 'package:example/feature/animated/routing/animated_route.dart';
import 'package:example/core/routing/app_navigator.dart';

/// Animated feature navigation sugar, added to the shared [AppNavigator].
extension AnimatedNav on AppNavigator {
  void toAnimated() => push(const AnimatedRoute());
}
