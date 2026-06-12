import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

/// Minimal [RouteNode] for engine tests. Identity (key/equality) derives from
/// [name], so distinct names are distinct nodes.
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
}
