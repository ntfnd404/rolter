import 'animated_route_name.dart';
import '../../../navigation/app_route.dart';
import 'package:flutter/foundation.dart';

/// Flat route rendered with a bespoke slide-up and fade transition.
final class AnimatedRoute extends AppRoute {
  const AnimatedRoute();

  @override
  LocalKey get pageKey => const ValueKey('animated');

  @override
  String get name => AnimatedRouteName.animated.wire;

  @override
  Map<String, String> toParams() => const {};
}
