import 'package:example/feature/home/routing/home_route_name.dart';
import 'package:example/feature/home/view/home_screen.dart';
import 'package:example/core/routing/app_route.dart';
import 'package:flutter/material.dart';

/// Landing route.
final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  LocalKey get pageKey => const ValueKey('home');

  @override
  String get name => HomeRouteName.home.wire;

  @override
  Map<String, String> toParams() => const {};

  @override
  Page<Object?> buildPage(BuildContext context) =>
      MaterialPage(key: pageKey, child: const HomeScreen());
}
