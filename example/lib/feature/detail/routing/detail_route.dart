import 'detail_route_name.dart';
import '../view/detail_screen.dart';
import '../../../core/routing/app_route.dart';
import 'package:flutter/material.dart';

/// Flat detail with a typed [id], pushed on top of Home (`/home/detail~id=5`).
final class DetailRoute extends AppRoute {
  const DetailRoute(this.id);

  final int id;

  @override
  LocalKey get pageKey => ValueKey('detail:$id');

  @override
  String get name => DetailRouteName.detail.wire;

  @override
  Map<String, String> toParams() => {'id': '$id'};

  @override
  Page<Object?> buildPage(BuildContext context) =>
      MaterialPage(key: pageKey, child: DetailScreen(id: id));
}
