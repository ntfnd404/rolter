import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

/// Minimal [RouteNode] for engine tests. Has explicit value equality over
/// [name] + [children] (not leaning on `const` canonicalisation), so it works
/// as both a leaf and a shell node in the tree tests.
@immutable
class TestRoute implements RouteNode {
  const TestRoute(this.name, {this.children = const []});

  @override
  final String name;

  @override
  final List<RouteNode> children;

  @override
  LocalKey get pageKey => ValueKey(name);

  @override
  Map<String, String> toParams() => const {};

  @override
  RouteNode withChildren(List<RouteNode> children) =>
      TestRoute(name, children: children);

  @override
  Page<Object?> buildPage(BuildContext context) =>
      const MaterialPage(child: SizedBox());

  @override
  int get hashCode => Object.hash(name, Object.hashAll(children));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestRoute &&
          other.name == name &&
          listEquals(other.children, children);
}
