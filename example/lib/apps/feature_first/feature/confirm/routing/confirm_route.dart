import 'confirm_route_name.dart';
import '../../../navigation/app_route.dart';
import 'package:flutter/foundation.dart';

/// Confirmation dialog represented as a URL-addressable route.
final class ConfirmRoute extends AppRoute {
  const ConfirmRoute(this.message);

  final String message;

  @override
  LocalKey get pageKey => ValueKey('confirm:$message');

  @override
  String get name => ConfirmRouteName.confirm.wire;

  @override
  Map<String, String> toParams() => {'message': message};
}
