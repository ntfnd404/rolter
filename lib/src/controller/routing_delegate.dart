import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:rolter/src/model/route_node.dart';
import 'package:rolter/src/state/routes_state.dart';

/// Generic, screen-agnostic [RouterDelegate]. Never subclassed per app: routes
/// build their own pages polymorphically via [RouteNode.buildPage].
class RoutingDelegate<R extends RouteNode> extends RouterDelegate<List<R>>
    with ChangeNotifier {
  /// Creates a delegate that renders and mutates [_state], optionally with a
  /// [transitionDelegate] for the root navigator (e.g.
  /// `NoAnimationTransitionDelegate` on web).
  RoutingDelegate(this._state, {this.transitionDelegate}) {
    _state.addListener(notifyListeners);
  }

  /// Final field (never a getter) so `popRoute` and `build` read the same key.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Transition delegate for the root navigator. Defaults to the framework's
  /// [DefaultTransitionDelegate].
  final TransitionDelegate<Object?>? transitionDelegate;

  final RoutesState<R> _state;

  @override
  List<R> get currentConfiguration => _state.root;

  @override
  Future<bool> popRoute() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return SynchronousFuture<bool>(false);
    }

    return navigator.maybePop();
  }

  @override
  Future<void> setNewRoutePath(List<R> configuration) {
    _state.setRoot(configuration);

    return SynchronousFuture<void>(null);
  }

  @override
  Widget build(BuildContext context) => Navigator(
    key: navigatorKey,
    transitionDelegate:
        transitionDelegate ?? const DefaultTransitionDelegate<Object?>(),
    pages: <Page<Object?>>[
      for (final route in _state.root) route.buildPage(context),
    ],
    onDidRemovePage: _onDidRemovePage,
  );

  @override
  void dispose() {
    _state.removeListener(notifyListeners);
    super.dispose();
  }

  void _onDidRemovePage(Page<Object?> page) {
    final key = page.key;
    if (key != null) {
      _state.removeByPageKey(key);
    }
  }
}
