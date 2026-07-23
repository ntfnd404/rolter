import '../../../core/routing/app_route.dart';
import '../../home/routing/home_route.dart';
import '../application/session_lock.dart';
import 'lock_route.dart';
import '../../tabbed_stack/shell/routing/tabs_route.dart';
import 'package:flutter/foundation.dart';
import 'package:rolter/rolter.dart';

/// Redirects protected routes ([TabsRoute]) to [LockRoute] while locked,
/// remembering the intended location in a [PendingLocation].
///
/// Depends on the read-only [SessionLock] (ISP) — not on `LockBloc`: routing
/// reads the lock and bridges its `changes` stream to the guard's `Listenable`
/// via [StreamListenable]. The bloc observes the same source for the UI — guard
/// and bloc are siblings over one source of truth, neither knows the other.
final class LockGuard implements RouteGuard<AppRoute> {
  LockGuard(this._lock) {
    _refresh = StreamListenable(_lock.changes);
  }

  final SessionLock _lock;
  late final StreamListenable _refresh;
  final PendingLocation<AppRoute> _pending = PendingLocation<AppRoute>();

  @override
  void addListener(VoidCallback listener) => _refresh.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _refresh.removeListener(listener);

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

  /// Cancels the change-stream bridge. The service's lifecycle is owned by the
  /// composition root.
  void dispose() => _refresh.dispose();
}
