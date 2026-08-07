/// Wire names for the Animated (custom-transition) feature's routes.
enum AnimatedRouteName {
  animated('animated');

  const AnimatedRouteName(this.wire);

  /// URL segment and registry key.
  final String wire;
}
