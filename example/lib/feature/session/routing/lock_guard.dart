import 'package:example/feature/home/routing/home_route.dart';
import 'package:example/feature/items/routing/tabs_route.dart';
import 'package:example/feature/session/di/lock_controller.dart';
import 'package:example/feature/session/routing/lock_route.dart';
import 'package:example/routing/app_route.dart';
import 'package:flutter/foundation.dart';
import 'package:rolter/rolter.dart';

/// Redirects protected routes ([TabsRoute]) to [LockRoute] while locked,
/// remembering the intended location in a [PendingLocation]. When
/// [LockController] changes, the guard's `Listenable` fires, the pipeline
/// reruns, and the remembered intent is restored.
class LockGuard with ChangeNotifier implements RouteGuard<AppRoute> {
  LockGuard(this._lock) {
    _lock.addListener(notifyListeners);
  }

  final LockController _lock;

  final PendingLocation<AppRoute> _pending = PendingLocation<AppRoute>();

  @override
  GuardResult<AppRoute> call(
    List<List<AppRoute>> history,
    List<AppRoute> requested,
    Map<String, Object?> context,
  ) {
    final wantsProtected = requested.any((route) => route is TabsRoute);
    final onLockScreen = requested.any((route) => route is LockRoute);

    if (_lock.isLocked) {
      if (wantsProtected && !onLockScreen) {
        _pending.remember(requested);
        return const GuardResult.proceed([HomeRoute(), LockRoute()]);
      }
      return GuardResult.proceed(requested);
    }

    if (_pending.hasPending && onLockScreen) {
      return GuardResult.proceed(_pending.take()!);
    }
    return GuardResult.proceed(requested);
  }

  @override
  void dispose() {
    _lock.removeListener(notifyListeners);
    super.dispose();
  }
}
