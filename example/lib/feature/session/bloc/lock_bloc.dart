import 'dart:async';

import '../application/session_lock_service.dart';
import 'lock_event.dart';
import 'lock_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Session lock as a full [Bloc] (events → state) — the bloc-based counterpart
/// to the `scope` feature's `ChangeNotifier`.
///
/// UI events mutate the [SessionLockService]; the bloc also subscribes to its
/// `changes`, so its state always mirrors the source of truth (one-way flow:
/// event → service → stream → state). It does NOT own the lock — the service
/// does, and the route guard observes the same source independently.
class LockBloc extends Bloc<LockEvent, LockState> {
  LockBloc(this._lock) : super(LockState(isLocked: _lock.isLocked)) {
    on<LockRequested>((event, emit) => _lock.lock());
    on<UnlockRequested>((event, emit) => _lock.unlock());
    on<LockStateChanged>(
      (event, emit) => emit(LockState(isLocked: event.isLocked)),
    );

    _subscription = _lock.changes.listen(
      (isLocked) => add(LockStateChanged(isLocked)),
    );
  }

  final SessionLockService _lock;
  late final StreamSubscription<bool> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();

    return super.close();
  }
}
