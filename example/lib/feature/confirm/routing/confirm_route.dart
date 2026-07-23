import 'confirm_route_name.dart';
import '../view/confirm_dialog.dart';
import '../../../core/routing/app_navigator.dart';
import '../../../core/routing/app_route.dart';
import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

/// Confirmation dialog as a URL-addressable route via [TransparentPage].
final class ConfirmRoute extends AppRoute {
  const ConfirmRoute(this.message);

  final String message;

  @override
  LocalKey get pageKey => ValueKey('confirm:$message');

  @override
  String get name => ConfirmRouteName.confirm.wire;

  @override
  Map<String, String> toParams() => {'message': message};

  @override
  Page<Object?> buildPage(BuildContext context) => TransparentPage<bool>(
    key: pageKey,
    child: ConfirmDialog(
      message: message,
      onConfirm: () => context.navigator.popWith<bool>(true),
      onCancel: () => context.navigator.popWith<bool>(false),
    ),
  );
}
