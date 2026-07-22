import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/route_node.dart';

/// Processes one tree snapshot: runs the apply pipeline (normalise, later
/// guards) and commits the result.
typedef SnapshotProcessor<R extends RouteNode> = Future<void> Function(
  List<R> snapshot,
);

/// Serialises navigation: every intent enqueues a full target snapshot and the
/// queue processes them one at a time, so async work (a guard's `await`) never
/// races. An intent that arrives mid-flight simply queues behind the current
/// one.
class NavigationQueue<R extends RouteNode> {
  /// Creates a queue that drains enqueued snapshots through [_process].
  NavigationQueue(this._process);
  final SnapshotProcessor<R> _process;
  final List<List<R>> _buffer = <List<R>>[];
  Future<void>? _running;

  /// Whether the queue is currently draining.
  bool get isProcessing => _running != null;

  /// Completes once the queue is idle — useful for tests.
  Future<void> get processingCompleted =>
      _running ?? SynchronousFuture<void>(null);

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
    }
  }
}
