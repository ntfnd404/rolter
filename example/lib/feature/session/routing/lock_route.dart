import 'package:example/feature/session/routing/session_route_name.dart';
import 'package:example/feature/session/view/unlock_screen.dart';
import 'package:example/core/routing/app_route.dart';
import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

/// Redirect target of the lock guard. Kept out of browser history. Built as a
/// [NoAnimationPage] so the lock appears instantly when a guard redirects to it,
/// rather than sliding in like a normal push.
final class LockRoute extends AppRoute implements HistoryExcluded {
  const LockRoute();

  @override
  LocalKey get pageKey => const ValueKey('lock');

  @override
  String get name => SessionRouteName.lock.wire;

  @override
  Map<String, String> toParams() => const {};

  @override
  Page<Object?> buildPage(BuildContext context) =>
      NoAnimationPage(key: pageKey, child: const UnlockScreen());
}
