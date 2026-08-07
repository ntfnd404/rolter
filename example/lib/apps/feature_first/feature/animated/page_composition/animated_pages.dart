import '../view/animated_screen.dart';
import '../../../composition/app_route_page_catalog.dart';
import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

import '../routing/animated_route.dart';

/// Animated feature page contribution.
final AppRoutePageDefinition animatedPageDefinition =
    TypedAppRoutePageDefinition<AnimatedRoute>(
      pageFactory: (context, route, nestedPageBuilder) => TransitionPage(
        key: route.pageKey,
        name: route.name,
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
      ),
    );
