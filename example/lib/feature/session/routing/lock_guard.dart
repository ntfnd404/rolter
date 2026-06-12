import 'package:example/feature/home/routing/home_route.dart';
import 'package:example/feature/items/routing/tabs_route.dart';
import 'package:example/feature/session/di/lock_controller.dart';
import 'package:example/feature/session/routing/lock_route.dart';
import 'package:example/routing/app_route.dart';
import 'package:flutter/foundation.dart';
import 'package:rolter/rolter.dart';

/// Redirects protected routes ([TabsRoute]) to [LockRoute] while locked,
/// remembering the intended location. When [LockController] changes, the guard's
/// `Listenable` fires, the pipeline reruns, and the intent is restored.
class LockGuard with ChangeNotifier implements RouteGuard<AppRoute> {
  LockGuard(this._lock) {
    _lock.addListener(notifyListeners);
  }

  final LockController _lock;

  List<AppRoute>? _intended;

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
        _intended = requested;
        return const GuardResult.proceed([HomeRoute(), LockRoute()]);
      }
      return GuardResult.proceed(requested);
    }

    final intended = _intended;
    if (intended != null && onLockScreen) {
      _intended = null;
      return GuardResult.proceed(intended);
    }
    return GuardResult.proceed(requested);
  }

  @override
  void dispose() {
    _lock.removeListener(notifyListeners);
    super.dispose();
  }
}
