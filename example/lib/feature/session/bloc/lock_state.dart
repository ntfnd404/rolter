import 'package:flutter/foundation.dart';

/// State of [LockBloc]. A proper value-class state (not a bare `bool`), so it can
/// grow more fields (e.g. `attemptsRemaining`, `lastUnlockedAt`) without changing
/// the bloc's type. Value equality lets the bloc skip no-op emits.
@immutable
class LockState {
  const LockState({required this.isLocked});

  /// The initial, unlocked state.
  const LockState.unlocked() : isLocked = false;

  /// Whether the session is currently locked.
  final bool isLocked;

  LockState copyWith({bool? isLocked}) =>
      LockState(isLocked: isLocked ?? this.isLocked);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LockState && other.isLocked == isLocked);

  @override
  int get hashCode => isLocked.hashCode;
}
