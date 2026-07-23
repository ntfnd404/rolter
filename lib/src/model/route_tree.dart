import 'package:flutter/foundation.dart';

import 'route_node.dart';

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

/// Returns the first [RouteNode.pageKey] that occurs more than once anywhere in
/// the tree, or `null` if every key is unique. Used to enforce the Navigator's
/// unique-page-key requirement (see `RouteNode.pageKey`).
LocalKey? firstDuplicatePageKey<R extends RouteNode>(List<R> roots) {
  final seen = <LocalKey>{};
  LocalKey? duplicate;

  void visit(List<RouteNode> nodes) {
    for (final node in nodes) {
      if (duplicate != null) {
        return;
      }
      if (!seen.add(node.pageKey)) {
        duplicate = node.pageKey;

        return;
      }
      visit(node.children);
    }
  }

  visit(roots);

  return duplicate;
}

/// Returns [roots] truncated so its top is the topmost node satisfying [test]
/// (i.e. pops from the top until the predicate holds). If no node matches,
/// [roots] is returned unchanged — never empties the stack. Operates on the
/// root stack; the predicate is over the typed [R], not a `Route`.
List<R> popUntil<R extends RouteNode>(
  List<R> roots,
  bool Function(R node) test,
) {
  final index = roots.lastIndexWhere(test);

  return index < 0 ? roots : roots.sublist(0, index + 1);
}

/// Returns [roots] with every node satisfying [test] removed. May shorten the
/// stack to empty (the caller's `normalize` should restore a root if needed).
List<R> removeWhere<R extends RouteNode>(
  List<R> roots,
  bool Function(R node) test,
) => <R>[
  for (final node in roots)
    if (!test(node)) node,
];

/// Returns [roots] reset to the prefix up to and including the topmost node
/// satisfying [test], with [route] pushed on top. If no node matches, the
/// result is just `[route]` (a full reset) — the declarative analogue of
/// `Navigator.pushAndRemoveUntil`.
List<R> pushAndResetTo<R extends RouteNode>(
  List<R> roots,
  R route,
  bool Function(R node) test,
) {
  final index = roots.lastIndexWhere(test);
  final kept = index < 0 ? <R>[] : roots.sublist(0, index + 1);

  return <R>[...kept, route];
}

/// Returns a description of the first parent → disallowed-child relationship in
/// the tree, or `null` if it is consistent. Only nodes implementing
/// [StrictHierarchy] are checked. Used as a development-time diagnostic.
String? hierarchyViolation<R extends RouteNode>(List<R> roots) {
  String? violation;

  void visit(List<RouteNode> nodes) {
    for (final node in nodes) {
      if (violation != null) {
        return;
      }
      if (node is StrictHierarchy) {
        final strict = node as StrictHierarchy;
        for (final child in node.children) {
          if (!strict.allowsChild(child)) {
            violation = '"${node.name}" does not allow child "${child.name}"';

            return;
          }
        }
      }
      visit(node.children);
    }
  }

  visit(roots);

  return violation;
}
