import 'package:flutter/material.dart';

/// Overlay page: non-opaque route with a scrim barrier and no transition.
/// Use for popups, dialogs, and bottom sheets that should be
/// URL-addressable tree nodes (back closes them, deep links open them).
///
/// Theming: the barrier defaults to the theme's `colorScheme.scrim`
/// (override via [barrierColor]); the content widget themes itself like any
/// other widget.
class TransparentPage<T> extends Page<T> {
  /// Creates a transparent overlay page that shows [child].
  const TransparentPage({
    required this.child,
    this.barrierColor,
    this.barrierDismissible = true,
    super.key,
    super.name,
    super.arguments,
  });

  /// The widget shown over the barrier.
  final Widget child;

  /// Color of the modal barrier; defaults to `colorScheme.scrim` at 50%
  /// opacity.
  final Color? barrierColor;

  /// Whether tapping the barrier pops this page.
  final bool barrierDismissible;

  @override
  Route<T> createRoute(BuildContext context) => PageRouteBuilder<T>(
        settings: this,
        opaque: false,
        barrierColor:
            barrierColor ?? Theme.of(context).colorScheme.scrim.withAlpha(128),
        barrierDismissible: barrierDismissible,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) => child,
      );
}
