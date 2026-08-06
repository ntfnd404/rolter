import 'animated_route.dart';
import '../../../navigation/app_navigator.dart';

/// Animated feature navigation sugar, added to the shared [AppNavigator].
extension AnimatedNav on AppNavigator {
  void toAnimated() => push(const AnimatedRoute());
}
