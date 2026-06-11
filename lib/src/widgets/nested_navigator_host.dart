import 'package:flutter/widgets.dart';

import 'package:rolter/src/controller/navigation_service.dart';
import 'package:rolter/src/model/route_node.dart';
import 'package:rolter/src/model/route_tree.dart';

/// Hosts a child [Navigator] over the children of the tree node at [path].
///
/// A shell/tab route returns `MaterialPage(child: NestedNavigatorHost(...))`.
/// The inner navigator's pops mutate that subtree of the single
/// source-of-truth tree via [NavigationService.mutateAt] (same removal logic
/// as the root delegate). When [active] (e.g. this is the visible tab), the
/// host takes back-button priority so system back targets it first;
/// otherwise it relinquishes it.
class NestedNavigatorHost<R extends RouteNode> extends StatefulWidget {
  /// Creates a host for the children of the node at [path].
  const NestedNavigatorHost({
    required this.service,
    required this.path,
    this.active = true,
    super.key,
  });

  /// Service used to read and mutate the navigation tree.
  final NavigationService<R> service;

  /// Path of the shell/tab node whose children this navigator hosts.
  final List<String> path;

  /// Whether this host should take back-button priority.
  final bool active;

  @override
  State<NestedNavigatorHost<R>> createState() => _NestedNavigatorHostState<R>();
}

class _NestedNavigatorHostState<R extends RouteNode>
    extends State<NestedNavigatorHost<R>> {
  BackButtonDispatcher? _parent;
  ChildBackButtonDispatcher? _childDispatcher;

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
    final parent = Router.of(context).backButtonDispatcher;
    if (parent != null && !identical(parent, _parent)) {
      _parent = parent;
      _childDispatcher = parent.createChildBackButtonDispatcher();
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
    final parent = _parent;
    final dispatcher = _childDispatcher;
    if (parent != null && dispatcher != null) {
      parent.forget(dispatcher);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = nodeAtPath<R>(widget.service.rootStack, widget.path);
    if (node == null) {
      return const SizedBox.shrink();
    }

    return Navigator(
      pages: <Page<Object?>>[
        for (final child in node.children) child.buildPage(context),
      ],
      onDidRemovePage: _onDidRemovePage,
    );
  }
}
