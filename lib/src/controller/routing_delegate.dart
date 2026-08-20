import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../model/route_node.dart';
import '../pages/route_page_builder.dart';
import '../state/routes_state.dart';

/// Generic, screen-agnostic [RouterDelegate].
///
/// Page composition is supplied through [pageBuilder], so route nodes may stay
/// data-only. Applications that prefer route-owned rendering can pass
/// `buildPageFromRouteNode`.
class RoutingDelegate<R extends RouteNode> extends RouterDelegate<List<R>>
    with ChangeNotifier {
  /// Creates a delegate that renders and mutates [_state], optionally with a
  /// [transitionDelegate] for the root navigator (e.g.
  /// `NoAnimationTransitionDelegate` on web).
  ///
  /// [pageBuilder] is required for every composition style:
  ///
  /// ```dart
  /// import 'package:flutter/material.dart';
  /// import 'package:rolter/rolter.dart';
  ///
  /// final state = RoutesState<RouteNode>(
  ///   const <RouteNode>[],
  ///   (routes) => routes,
  /// );
  /// final delegate = RoutingDelegate<RouteNode>(
  ///   state,
  ///   pageBuilder: (context, route) => MaterialPage<Object?>(
  ///     key: route.pageKey,
  ///     child: const SizedBox(),
  ///   ),
  /// );
  /// ```
  RoutingDelegate(
    this._state, {
    required RouteNodePageBuilder<R> pageBuilder,
    this.transitionDelegate,
  }) : _pageBuilder = pageBuilder {
    _state.addListener(notifyListeners);
  }

  /// Observes the root navigator so [popRoute] can reach its state without a
  /// `GlobalKey` (lighter, test-friendly, no element reparenting).
  final NavigatorObserver _navigatorObserver = NavigatorObserver();

  /// Transition delegate for the root navigator. Defaults to the framework's
  /// [DefaultTransitionDelegate].
  final TransitionDelegate<Object?>? transitionDelegate;

  final RoutesState<R> _state;
  final RouteNodePageBuilder<R> _pageBuilder;

  @override
  List<R> get currentConfiguration => _state.root;

  @override
  Future<bool> popRoute() {
    final navigator = _navigatorObserver.navigator;
    if (navigator == null) {
      return SynchronousFuture<bool>(false);
    }

    return navigator.maybePop();
  }

  /// Enqueues [configuration] and completes when the active route-state drain
  /// becomes idle. Calls made during one drain may share the same Future.
  @override
  Future<void> setNewRoutePath(List<R> configuration) {
    _state.setRoot(configuration);

    return _state.processingCompleted;
  }

  @override
  Widget build(BuildContext context) => Navigator(
    observers: <NavigatorObserver>[_navigatorObserver],
    transitionDelegate:
        transitionDelegate ?? const DefaultTransitionDelegate<Object?>(),
    pages: <Page<Object?>>[
      for (final route in _state.root)
        buildRoutePage<R>(
          pageBuilder: _pageBuilder,
          context: context,
          route: route,
        ),
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
