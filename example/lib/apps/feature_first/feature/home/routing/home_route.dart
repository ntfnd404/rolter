import 'home_route_name.dart';
import '../../../navigation/app_route.dart';
import 'package:flutter/foundation.dart';

/// Landing route.
final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  LocalKey get pageKey => const ValueKey('home');

  @override
  String get name => HomeRouteName.home.wire;

  @override
  Map<String, String> toParams() => const {};
}
