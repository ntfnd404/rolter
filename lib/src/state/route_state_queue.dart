import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:rolter/src/model/route_node.dart';

/// Processes one tree snapshot: runs the apply pipeline (normalise, later
/// guards) and commits the result.
typedef SnapshotProcessor<R extends RouteNode> =
    Future<void> Function(List<R> snapshot);

/// Serialises navigation: every intent enqueues a full target snapshot and the
/// queue processes them one at a time. This keeps async work (guards in v3,
/// async pop in v2) from racing. Hand-rolled equivalent of octopus's
/// `OctopusStateQueue`.
class RouteStateQueue<R extends RouteNode> {
  /// Creates a queue that drains enqueued snapshots through [_process].
  RouteStateQueue(this._process);
  final SnapshotProcessor<R> _process;
  final List<List<R>> _buffer = <List<R>>[];
  final List<Completer<void>> _idle = <Completer<void>>[];
  Future<void>? _running;

  /// Whether the queue is currently draining.
  bool get isProcessing => _running != null;

  /// Completes once the queue is idle — useful for tests.
  Future<void> get processingCompleted {
    if (_running == null) {
      return SynchronousFuture<void>(null);
    }

    final completer = Completer<void>();
    _idle.add(completer);

    return completer.future;
  }

  /// Enqueues [snapshot] and starts draining if idle.
  void add(List<R> snapshot) {
    _buffer.add(snapshot);
    _running ??= _drain();
  }

  Future<void> _drain() async {
    try {
      while (_buffer.isNotEmpty) {
        await _process(_buffer.removeAt(0));
      }
    } finally {
      _running = null;
      final pending = List<Completer<void>>.of(_idle);
      _idle.clear();
      for (final completer in pending) {
        completer.complete();
      }
    }
  }
}
