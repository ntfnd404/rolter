import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../model/route_node.dart';

/// Processes one immutable snapshot submitted to a [NavigationQueue].
///
/// This callback is trusted application code. A custom processor must apply
/// every policy required by its integration before it commits navigation.
/// Client-side route policy is not a substitute for server-side authorization.
typedef SnapshotProcessor<R extends RouteNode> =
    Future<void> Function(
      List<R> snapshot,
    );

/// A reusable FIFO serializer for custom navigation architectures.
///
/// Every [add] submits a complete target snapshot. Its top-level list is copied
/// into an unmodifiable list and snapshots are processed one at a time, so
/// asynchronous policy work cannot race with a later request. Route nodes and
/// their children remain application-owned and must themselves be immutable.
///
/// If the processor throws, the active drain fails and every snapshot waiting
/// behind the failed one is discarded. This fail-fast behavior prevents a
/// request that depended on an uncommitted intermediate state from running.
/// Await [processingCompleted] to observe the error. After it completes, a new
/// [add] starts a fresh drain explicitly.
///
/// The queue intentionally has no capacity policy: silently dropping, merging,
/// or rejecting navigation requests would change their meaning. An application
/// that produces requests at a high rate should debounce or rate-limit that
/// source before calling [add].
///
/// A [NavigationQueue] does not enforce authorization by itself. In particular,
/// an independently supplied [SnapshotProcessor] can omit route guards. Treat
/// that processor as trusted code and enforce access to protected data and
/// operations on the server as well.
class NavigationQueue<R extends RouteNode> {
  /// Creates a queue that drains submitted snapshots through its processor.
  NavigationQueue(this._process);

  final SnapshotProcessor<R> _process;
  final ListQueue<List<R>> _buffer = ListQueue<List<R>>();
  Future<void>? _running;

  /// Whether the queue is currently draining.
  bool get isProcessing => _running != null;

  /// Completes when the active drain becomes idle.
  ///
  /// The future completes with the processor's error when a snapshot fails.
  /// It is already complete when the queue is idle.
  Future<void> get processingCompleted =>
      _running ?? SynchronousFuture<void>(null);

  /// Enqueues an immutable copy of [snapshot] and starts draining if idle.
  void add(List<R> snapshot) {
    _buffer.addLast(List<R>.unmodifiable(snapshot));
    // Defer the drain until `_running` holds its Future. Besides making
    // isProcessing immediately accurate, this prevents a synchronously
    // failing processor from completing before the active drain is recorded.
    _running ??= Future<void>.microtask(_drain);
  }

  Future<void> _drain() async {
    try {
      while (_buffer.isNotEmpty) {
        await _process(_buffer.removeFirst());
      }
    } catch (_) {
      _buffer.clear();
      rethrow;
    } finally {
      _running = null;
    }
  }
}
