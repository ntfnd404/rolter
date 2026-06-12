import 'package:flutter/foundation.dart';

import 'package:rolter/src/model/route_node.dart';

/// Pure, immutable operations over the navigation tree.
///
/// The tree is an ordered list of [RouteNode]s with nested
/// [RouteNode.children]. N is tiny (a handful of nodes), so these favour
/// clarity and value-equality over algorithmic speed. Every operation
/// returns a new list; nothing is mutated in place.

/// Removes the node whose [RouteNode.pageKey] equals [key] from [roots].
///
/// Used by `onDidRemovePage` to drop exactly the page Flutter removed, rather
/// than assuming it was the top of the stack.
List<R> removeNodeByKey<R extends RouteNode>(List<R> roots, LocalKey key) =>
    <R>[
      for (final node in roots)
        if (node.pageKey != key) node,
    ];

/// Returns the node at [path] (matched by [RouteNode.name] per level), or
/// `null` if the path does not resolve.
R? nodeAtPath<R extends RouteNode>(List<R> roots, List<String> path) {
  if (path.isEmpty) {
    return null;
  }

  R? found;
  List<R> level = roots;
  for (final name in path) {
    found = null;
    for (final node in level) {
      if (node.name == name) {
        found = node;

        break;
      }
    }
    if (found == null) {
      return null;
    }
    level = found.children.cast<R>();
  }

  return found;
}

/// Rebuilds [roots] with the node at [path] replaced by `transform(node)`,
/// copying the spine via [RouteNode.withChildren]. Returns [roots] unchanged if
/// [path] does not resolve.
List<R> mutateNodeAt<R extends RouteNode>(
  List<R> roots,
  List<String> path,
  R Function(R node) transform,
) {
  if (path.isEmpty) {
    return roots;
  }

  final head = path.first;

  return <R>[
    for (final node in roots)
      if (node.name != head)
        node
      else if (path.length == 1)
        transform(node)
      else
        node.withChildren(
              mutateNodeAt<R>(
                node.children.cast<R>(),
                path.sublist(1),
                transform,
              ),
            )
            as R,
  ];
}

/// Collects every [RouteNode.pageKey] in the tree (root stack + all nested
/// children). Used to detect which pushed-for-result routes have left the tree.
Set<LocalKey> collectPageKeys<R extends RouteNode>(List<R> roots) {
  final keys = <LocalKey>{};

  void visit(List<RouteNode> nodes) {
    for (final node in nodes) {
      keys.add(node.pageKey);
      visit(node.children);
    }
  }

  visit(roots);

  return keys;
}
