import 'package:example/routing/app_route.dart';
import 'package:example/routing/not_found_screen.dart';
import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

/// System fallback for an unknown URL. Kept out of browser history. Lives in
/// `routing/` (not a feature) — it is the registry's fallback, not a domain
/// route, and its `'not-found'` wire name is a fixed system constant.
class NotFoundRoute extends AppRoute implements HistoryExcluded {
  const NotFoundRoute(this.attempted);

  final Uri attempted;

  @override
  LocalKey get pageKey => ValueKey('not-found:$attempted');

  @override
  String get name => 'not-found';

  @override
  Map<String, String> toParams() => {'u': attempted.toString()};

  @override
  Page<Object?> buildPage(BuildContext context) => MaterialPage(
    key: pageKey,
    child: NotFoundScreen(attempted: attempted),
  );
}
