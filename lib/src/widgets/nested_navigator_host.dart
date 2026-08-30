import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../model/route_node.dart';
import '../model/route_tree.dart';
import '../navigation/navigation_service.dart';
import '../pages/route_page_builder.dart';

/// Hosts a child [Navigator] over the children of the tree node at [path].
///
/// A shell/tab route returns `MaterialPage(child: NestedNavigatorHost(...))`.
/// The inner navigator's pops mutate that subtree of the single
/// source-of-truth tree via [NavigationService.mutateAt] (same removal logic
/// as the root delegate). When [active] (e.g. this is the visible tab), the
/// host takes back-button priority so system back targets it first; otherwise
/// it relinquishes it.
///
/// Nodes are addressed by [path] (precise even when names repeat per level).
/// The host observes the inner navigator (via a [NavigatorObserver]) to reach
/// its state, so the system back button targets it — not just the AppBar arrow.
/// Customise the inner navigator with [transitionDelegate] (e.g.
/// `NoAnimationTransitionDelegate`) and [onBackButtonPressed].
///
/// If the addressed node is absent or currently has no children, the host
/// renders an empty box instead of creating a `Navigator` with no pages. Empty
/// child lists remain valid route data; a nested Navigator is created
/// automatically when the subtree later becomes non-empty. An active empty
/// host lets Back bubble to its parent; without a nested Navigator there is no
/// state to pass to [onBackButtonPressed], so that override is not called.
class NestedNavigatorHost<R extends RouteNode> extends StatefulWidget {
  /// Creates a host for the children of the node at [path].
  const NestedNavigatorHost({
    required this.service,
    required this.path,
    required this.pageBuilder,
    this.active = true,
    this.transitionDelegate,
    this.onBackButtonPressed,
    super.key,
  });

  /// Service used to read and mutate the navigation tree.
  final NavigationService<R> service;

  /// Path of the shell/tab node whose children this navigator hosts.
  final List<String> path;

  /// Builds every page in the hosted child stack.
  ///
  /// Use the same composition strategy as the root delegate, or a deliberately
  /// isolated builder that supports every route type in this subtree.
  ///
  /// ```dart
  /// import 'package:flutter/material.dart';
  /// import 'package:rolter/rolter.dart';
  ///
  /// Widget buildNestedHost(NavigationService<RouteNode> navigator) =>
  /// NestedNavigatorHost<RouteNode>(
  ///   service: navigator,
  ///   path: const ['shell'],
  ///   pageBuilder: (context, route) => MaterialPage<Object?>(
  ///     key: route.pageKey,
  ///     child: const SizedBox(),
  ///   ),
  /// );
  /// ```
  final RouteNodePageBuilder<R> pageBuilder;

  /// Whether this host should take back-button priority.
  final bool active;

  /// Transition delegate for the inner navigator. Defaults to the framework's
  /// [DefaultTransitionDelegate]; pass `NoAnimationTransitionDelegate` for an
  /// instant nested stack, or a custom one for bespoke transitions.
  final TransitionDelegate<Object?>? transitionDelegate;

  /// Overrides the back action while [active]. Receives the inner navigator, so
  /// it can fall back to the default pop (`navigator.maybePop()`) and add app
  /// logic around it. Return `true` if the press was handled, `false` to let it
  /// bubble to the parent. Defaults to popping the inner navigator.
  /// This callback is not invoked while the addressed subtree is absent or
  /// empty because no inner [NavigatorState] exists.
  final Future<bool> Function(NavigatorState navigator)? onBackButtonPressed;

  @override
  State<NestedNavigatorHost<R>> createState() => _NestedNavigatorHostState<R>();
}

class _NestedNavigatorHostState<R extends RouteNode>
    extends State<NestedNavigatorHost<R>> {
  final NavigatorObserver _navigatorObserver = NavigatorObserver();
  BackButtonDispatcher? _parent;
  ChildBackButtonDispatcher? _childDispatcher;

  Future<bool> _handleBackButton() {
    final navigator = _navigatorObserver.navigator;
    if (navigator == null) {
      return SynchronousFuture<bool>(false);
    }
    final override = widget.onBackButtonPressed;
    if (override != null) {
      return override(navigator);
    }

    return navigator.maybePop();
  }

  void _syncPriority() {
    final parent = _parent;
    final dispatcher = _childDispatcher;
    if (parent == null || dispatcher == null) {
      return;
    }
    if (widget.active) {
      dispatcher.takePriority();
    } else {
      parent.forget(dispatcher);
    }
  }

  void _onDidRemovePage(Page<Object?> page) {
    final key = page.key;
    if (key == null) {
      return;
    }

    widget.service.mutateAt(
      widget.path,
      (node) =>
          node.withChildren(removeNodeByKey<RouteNode>(node.children, key))
              as R,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextParent = Router.of(context).backButtonDispatcher;
    if (!identical(nextParent, _parent)) {
      _disposeDispatcher();
      _parent = nextParent;
      if (nextParent != null) {
        _childDispatcher = nextParent.createChildBackButtonDispatcher()
          ..addCallback(_handleBackButton);
      }
    }
    _syncPriority();
  }

  @override
  void didUpdateWidget(NestedNavigatorHost<R> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _syncPriority();
    }
  }

  @override
  void dispose() {
    _disposeDispatcher();
    super.dispose();
  }

  void _disposeDispatcher() {
    final dispatcher = _childDispatcher;
    if (dispatcher != null) {
      dispatcher.removeCallback(_handleBackButton);
    }
    _childDispatcher = null;
    _parent = null;
  }

  @override
  Widget build(BuildContext context) {
    final node = nodeAtPath<R>(widget.service.rootStack, widget.path);
    // Flutter's pages API rejects an empty list. Treat a temporarily empty
    // subtree like a missing host rather than inventing a package-owned page.
    if (node == null || node.children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Navigator(
      observers: <NavigatorObserver>[_navigatorObserver],
      transitionDelegate:
          widget.transitionDelegate ??
          const DefaultTransitionDelegate<Object?>(),
      pages: <Page<Object?>>[
        for (final child in node.children)
          buildRoutePage<R>(
            pageBuilder: widget.pageBuilder,
            context: context,
            route: _typedChild(child),
          ),
      ],
      onDidRemovePage: _onDidRemovePage,
    );
  }

  R _typedChild(RouteNode child) {
    if (child is R) {
      return child;
    }
    throw StateError(
      'Nested route tree contains a child incompatible with the host route '
      'type.',
    );
  }
}
