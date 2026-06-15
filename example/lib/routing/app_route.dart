import 'package:rolter/rolter.dart';

/// Base for every route in the app.
///
/// Deliberately **not** `sealed`: routes live in their own feature folders, and
/// a sealed base would force them all into one library. Provides leaf defaults —
/// a nested route (tabs) overrides [children] / [withChildren]. Equality is
/// identity-by-key, so a leaf only needs a distinct [pageKey].
abstract class AppRoute implements RouteNode {
  const AppRoute();

  @override
  List<AppRoute> get children => const [];

  @override
  AppRoute withChildren(List<RouteNode> children) => this;

  @override
  int get hashCode => Object.hash(runtimeType, pageKey);

  @override
  bool operator ==(Object other) =>
      other is AppRoute &&
      other.runtimeType == runtimeType &&
      other.pageKey == pageKey;
}
