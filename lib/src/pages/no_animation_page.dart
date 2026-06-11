import 'package:flutter/material.dart';

/// Page with no transition animation (e.g. for web, or instant tab content).
class NoAnimationPage<T> extends Page<T> {
  /// Creates a page that shows [child] with no transition animation.
  const NoAnimationPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
  });

  /// The widget shown by this page.
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => PageRouteBuilder<T>(
    settings: this,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (_, _, _) => child,
  );
}
