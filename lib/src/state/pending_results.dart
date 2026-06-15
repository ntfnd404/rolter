import 'dart:async';

import 'package:flutter/foundation.dart';

/// Tracks the completers for in-flight `pushForResult` calls, keyed by the
/// pushed route's `pageKey`.
///
/// Pulled out of `RoutesState` so that state owns the *tree* and this owns the
/// *result lifecycle* (registration, explicit completion, drop-detection, and
/// teardown) — one responsibility each.
class PendingResults {
  final Map<LocalKey, Completer<Object?>> _byKey =
      <LocalKey, Completer<Object?>>{};

  /// Whether any results are still pending (lets the owner skip reconcile
  /// work).
  bool get isEmpty => _byKey.isEmpty;

  /// Registers a pending result for [key] and returns its future typed as `T?`.
  ///
  /// A result already pending for [key] is a programming error: it asserts in
  /// debug, and in release the prior awaiter is completed with `null` rather
  /// than leaked (result routes must have a unique `pageKey` while on the
  /// stack).
  Future<T?> register<T>(LocalKey key) {
    final existing = _byKey[key];
    assert(
      existing == null,
      'pushForResult: a result is already pending for pageKey "$key". Result '
      'routes must have a unique pageKey while on the stack (see '
      'RouteNode.pageKey).',
    );
    if (existing != null && !existing.isCompleted) {
      existing.complete();
    }
    final completer = Completer<Object?>();
    _byKey[key] = completer;

    return completer.future.then((value) => value as T?);
  }

  /// Completes the pending result for [key] with [result], if one exists.
  void complete(LocalKey key, Object? result) =>
      _byKey.remove(key)?.complete(result);

  /// Completes (with `null`) every pending result whose key is **not** in
  /// [present] — i.e. its route left the tree without an explicit result.
  void reconcileWith(Set<LocalKey> present) {
    if (_byKey.isEmpty) {
      return;
    }
    for (final key in _byKey.keys.toList()) {
      if (!present.contains(key)) {
        _byKey.remove(key)?.complete();
      }
    }
  }

  /// Completes all pending results with `null` and clears them (on dispose).
  void dispose() {
    for (final completer in _byKey.values) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    _byKey.clear();
  }
}
