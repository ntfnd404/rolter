import 'package:flutter/widgets.dart';

/// Page with no enter/exit transition (web, or instant tab/nested content).
///
/// Unlike a zero-duration `PageRouteBuilder`, this is a real [PageRoute]: it
/// keeps [maintainState]/[fullscreenDialog] and wraps its child in a route
/// [Semantics] scope (focus order a bare builder loses). To disable animation
/// for a *whole* nested stack, pass a `NoAnimationTransitionDelegate` to the
/// navigator instead of making every page a [NoAnimationPage].
class NoAnimationPage<T> extends Page<T> {
  /// Creates a page that shows [child] with no enter/exit transition.
  const NoAnimationPage({
    required this.child,
    this.maintainState = true,
    this.fullscreenDialog = false,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// The widget shown by this page.
  final Widget child;

  /// Whether the route stays in memory while it is not the top of the stack.
  final bool maintainState;

  /// Whether this page is presented as a full-screen dialog.
  final bool fullscreenDialog;

  @override
  Route<T> createRoute(BuildContext context) => _NoAnimationPageRoute<T>(this);
}

class _NoAnimationPageRoute<T> extends PageRoute<T> {
  _NoAnimationPageRoute(NoAnimationPage<T> page) : super(settings: page);

  NoAnimationPage<T> get _page => settings as NoAnimationPage<T>;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  bool get opaque => true;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is PageRoute;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) =>
      previousRoute is PageRoute;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: _page.child,
      );
}
