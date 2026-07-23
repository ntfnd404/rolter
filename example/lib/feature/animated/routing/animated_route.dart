import 'animated_route_name.dart';
import '../view/animated_screen.dart';
import '../../../core/routing/app_route.dart';
import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

/// Flat route demonstrating a custom transition via the engine's
/// [TransitionPage] — a bespoke slide-up + fade with no custom `Page` subclass.
final class AnimatedRoute extends AppRoute {
  const AnimatedRoute();

  @override
  LocalKey get pageKey => const ValueKey('animated');

  @override
  String get name => AnimatedRouteName.animated.wire;

  @override
  Map<String, String> toParams() => const {};

  @override
  Page<Object?> buildPage(BuildContext context) => TransitionPage(
    key: pageKey,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
    child: const AnimatedScreen(),
  );
}
