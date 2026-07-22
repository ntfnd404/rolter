import 'package:flutter/widgets.dart';

/// A reusable page for a custom transition without writing a [Route] subclass.
///
/// Pass a [transitionsBuilder] (and optionally [transitionDuration] /
/// [opaque]) and it wires a [PageRouteBuilder] for you — the common case for a
/// bespoke fade/slide/scale. For richer route semantics (drag-to-dismiss,
/// a barrier, predictive back, `secondaryAnimation` coordination) subclass
/// [PageRoute] directly, the way `NoAnimationPage` does. To suppress animation
/// across a *whole* nested stack, pass a `TransitionDelegate` to the navigator
/// instead.
class TransitionPage<T> extends Page<T> {
  /// Creates a page that wraps [child] in [transitionsBuilder].
  const TransitionPage({
    required this.child,
    required this.transitionsBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
    this.opaque = true,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// The widget shown by this page.
  final Widget child;

  /// Builds the transition wrapping [child] (e.g. fade, slide, scale).
  final RouteTransitionsBuilder transitionsBuilder;

  /// Duration of the enter transition.
  final Duration transitionDuration;

  /// Duration of the reverse (pop) transition.
  final Duration reverseTransitionDuration;

  /// Whether the route is opaque (covers routes beneath it).
  final bool opaque;

  @override
  Route<T> createRoute(BuildContext context) => PageRouteBuilder<T>(
        settings: this,
        opaque: opaque,
        transitionDuration: transitionDuration,
        reverseTransitionDuration: reverseTransitionDuration,
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: transitionsBuilder,
      );
}
