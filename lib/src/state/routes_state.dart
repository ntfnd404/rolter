import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:rolter/src/model/route_node.dart';
import 'package:rolter/src/model/route_tree.dart';
import 'package:rolter/src/state/navigation_queue.dart';

/// Transforms a requested stack into the committed stack: normalises and, in
/// v3, folds it through guards. May be sync (v1 normalise) or async (v3
/// guards) — the queue awaits it either way. v1 wiring passes a
/// normalise-only function.
typedef ApplyPipeline<R extends RouteNode> =
    FutureOr<List<R>> Function(List<R> requested);

/// Single source of truth for the navigation tree.
///
/// Every intent computes a full target snapshot and enqueues it; the queue
/// commits via [ApplyPipeline] and notifies listeners only on a real change.
class RoutesState<R extends RouteNode> extends ChangeNotifier {
  /// Creates a state with [initial] as the committed root, applying
  /// [_pipeline] to every subsequent change.
  RoutesState(List<R> initial, this._pipeline) : _root = List<R>.of(initial) {
    _queue = NavigationQueue<R>(_commit);
  }
  final ApplyPipeline<R> _pipeline;
  final Map<LocalKey, Completer<Object?>> _results =
      <LocalKey, Completer<Object?>>{};
  late final NavigationQueue<R> _queue;
  List<R> _root;
  List<R>? _pending;

  /// Committed root stack (read-only view).
  List<R> get root => List<R>.unmodifiable(_root);

  /// Top of the committed stack.
  R get top => _root.last;

  /// Whether the root stack can pop.
  bool get canPop => _root.length > 1;

  /// Exposes the queue so callers can await idle (e.g. tests).
  NavigationQueue<R> get queue => _queue;

  // Latest enqueued target (or committed root) so rapid relative ops compose.
  List<R> get _base => _pending ?? _root;

  /// Replaces the whole stack with [stack].
  void setRoot(List<R> stack) => _enqueue(List<R>.of(stack));

  /// Pushes [route] onto the stack.
  void push(R route) => _enqueue(<R>[..._base, route]);

  /// Pops the top of the stack, if more than one node remains.
  void pop() {
    final base = _base;
    if (base.length > 1) {
      _enqueue(base.sublist(0, base.length - 1));
    }
  }

  /// Replaces the top of the stack with [route].
  void replaceTop(R route) {
    final base = _base;
    _enqueue(<R>[...base.sublist(0, base.length - 1), route]);
  }

  /// Replaces the whole stack with a single [route].
  void clearAndPush(R route) => _enqueue(<R>[route]);

  /// Pushes [route], or replaces the top if it has the same type.
  void pushOrReplaceTop(R route) => _base.last.runtimeType == route.runtimeType
      ? replaceTop(route)
      : push(route);

  /// Removes the node identified by [key] from the stack.
  void removeByPageKey(LocalKey key) =>
      _enqueue(removeNodeByKey<R>(_base, key));

  /// Replaces the node at [path] with the result of [transform].
  void mutateAt(List<String> path, R Function(R node) transform) =>
      _enqueue(mutateNodeAt<R>(_base, path, transform));

  /// Re-applies the current stack through the pipeline. Wire this to a
  /// `GuardedPipeline.refresh` so guards rerun when their state changes.
  void reevaluate() => _enqueue(_base);

  /// Pushes [route] and completes with the result passed to [popWith], or null
  /// if the route leaves the tree without one (e.g. system back).
  Future<T?> pushForResult<T>(R route) {
    final completer = Completer<Object?>();
    _results[route.pageKey] = completer;
    push(route);

    return completer.future.then((value) => value as T?);
  }

  /// Completes the top route's pending result with [result] and pops it.
  void popWith<T>(T result) {
    _results.remove(top.pageKey)?.complete(result);
    pop();
  }

  @override
  void dispose() {
    for (final completer in _results.values) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    _results.clear();
    super.dispose();
  }

  void _enqueue(List<R> target) {
    _pending = target;
    _queue.add(target);
  }

  Future<void> _commit(List<R> requested) async {
    final next = await _pipeline(requested);
    if (identical(_pending, requested)) {
      _pending = null;
    }
    if (!listEquals(_root, next)) {
      _root = next;
      _completeDroppedResults();
      notifyListeners();
    }
  }

  void _completeDroppedResults() {
    if (_results.isEmpty) {
      return;
    }
    final present = collectPageKeys<R>(_root);
    for (final key in _results.keys.toList()) {
      if (!present.contains(key)) {
        _results.remove(key)?.complete();
      }
    }
  }
}
