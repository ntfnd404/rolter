import '../../../navigation/app_route.dart';
import 'package:flutter/foundation.dart';
import 'package:rolter/rolter.dart';

/// System fallback for an unknown URL. Kept out of browser history — it is the
/// registry's fallback, not a domain route, and its `'not-found'` wire name is
/// a fixed system constant. Its own feature folder: the route + its screen,
/// with no domain logic.
class NotFoundRoute extends AppRoute implements HistoryExcluded {
  const NotFoundRoute(this.attempted);

  final Uri attempted;

  @override
  LocalKey get pageKey => ValueKey('not-found:$attempted');

  @override
  String get name => 'not-found';

  @override
  Map<String, String> toParams() => {'u': attempted.toString()};
}
