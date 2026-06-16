import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapts a [Stream] into a [Listenable] so a `Stream`-based store — a `bloc`,
/// a `Cubit` (via `.stream`), an `rxdart` subject, etc. — can drive a
/// [RouteGuard] / `GuardedPipeline.refresh`.
///
/// A [RouteGuard] is a [Listenable]: the pipeline reruns the guards whenever a
/// guard fires. Blocs are `Stream`s, not `Listenable`s, so a guard that gates
/// on bloc state needs a bridge. Instead of hand-rolling listener plumbing (or
/// mixing in a `ChangeNotifier`) in every guard, compose one of these and
/// delegate [addListener] / [removeListener] to it — then read the current
/// value synchronously from the bloc's `state` inside the guard:
///
/// ```dart
/// final class LockGuard implements RouteGuard<AppRoute> {
///   LockGuard(this._bloc) {
///     _refresh = StreamListenable(_bloc.stream);
///   }
///   final LockBloc _bloc;
///   late final StreamListenable _refresh;
///
///   @override
///   void addListener(VoidCallback l) => _refresh.addListener(l);
///   @override
///   void removeListener(VoidCallback l) => _refresh.removeListener(l);
///
///   // ... call() reads _bloc.state synchronously ...
///
///   void dispose() => _refresh.dispose();
/// }
/// ```
///
/// It [notifyListeners] on every stream event; pass an already-`distinct()`
/// stream (or map to the field you gate on) to avoid redundant pipeline reruns.
/// It does not retain the latest value — read it from the source's own current
/// state. Always [dispose] it to cancel the subscription.
class StreamListenable extends ChangeNotifier {
  /// Subscribes to [source] and fires this [Listenable] on each event.
  StreamListenable(Stream<Object?> source) {
    _subscription = source.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
