import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:rolter/src/model/route_node.dart';
import 'package:rolter/src/model/route_tree.dart' as tree;
import 'package:rolter/src/state/nav_observer.dart';
import 'package:rolter/src/state/navigation_queue.dart';
import 'package:rolter/src/state/pending_results.dart';

/// Transforms a requested stack into the committed stack — typically normalises
/// it and folds it through guards. May be sync or async; the queue awaits it
/// either way.
typedef ApplyPipeline<R extends RouteNode> =
    FutureOr<List<R>> Function(List<R> requested);

/// Single source of truth for the navigation tree.
///
/// Every intent computes a full target snapshot and enqueues it; the queue
/// commits via [ApplyPipeline] and notifies listeners only on a real change.
class RoutesState<R extends RouteNode> extends ChangeNotifier {
  /// Creates a state with [initial] as the committed root, applying
  /// [_pipeline] to every subsequent change. [observers] receive a read-only
  /// [NavTransition] after each committed change (telemetry only).
  RoutesState(
    List<R> initial,
    this._pipeline, {
    List<NavObserver<R>> observers = const [],
  }) : _root = List<R>.of(initial) {
    _observers = observers;
    _queue = NavigationQueue<R>(_commit);
  }
  final ApplyPipeline<R> _pipeline;
  late final List<NavObserver<R>> _observers;
  final PendingResults _results = PendingResults();
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
      _enqueue(tree.removeNodeByKey<R>(_base, key));

  /// Replaces the node at [path] with the result of [transform].
  void mutateAt(List<String> path, R Function(R node) transform) =>
      _enqueue(tree.mutateNodeAt<R>(_base, path, transform));

  /// Pops from the top until the top satisfies [test] (no-op if none match).
  void popUntil(bool Function(R node) test) =>
      _enqueue(tree.popUntil<R>(_base, test));

  /// Removes every node in the stack that satisfies [test].
  void removeWhere(bool Function(R node) test) =>
      _enqueue(tree.removeWhere<R>(_base, test));

  /// Resets the stack to the topmost node matching [test] (or clears it if none
  /// match), then pushes [route] on top.
  void pushAndResetTo(R route, bool Function(R node) test) =>
      _enqueue(tree.pushAndResetTo<R>(_base, route, test));

  /// Re-applies the current stack through the pipeline. Wire this to a
  /// `GuardedPipeline.refresh` so guards rerun when their state changes.
  void reevaluate() => _enqueue(_base);

  /// Pushes [route] and completes with the result passed to [popWith], or null
  /// if the route leaves the tree without one (e.g. system back).
  ///
  /// Results are keyed by [RouteNode.pageKey], so a result route must have a
  /// unique `pageKey` while it is on the stack (the same uniqueness the
  /// Navigator requires of its pages). Pushing a second result route with a
  /// `pageKey` that is already pending is a programming error: it asserts in
  /// debug, and in release the prior awaiter is completed with `null` rather
  /// than leaked.
  Future<T?> pushForResult<T>(R route) {
    final future = _results.register<T>(route.pageKey);
    push(route);

    return future;
  }

  /// Completes the top route's pending result with [result] and pops it.
  void popWith<T>(T result) {
    _results.complete(top.pageKey, result);
    pop();
  }

  @override
  void dispose() {
    _results.dispose();
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
    assert(
      tree.firstDuplicatePageKey<R>(next) == null,
      'rolter: the committed stack has a duplicate pageKey '
      '(${tree.firstDuplicatePageKey<R>(next)}). Every RouteNode.pageKey must '
      'be unique across the whole tree — encode identity-bearing params into '
      'pageKey (see RouteNode.pageKey).',
    );
    assert(
      tree.hierarchyViolation<R>(next) == null,
      'rolter: strict-hierarchy violation in the committed stack — '
      '${tree.hierarchyViolation<R>(next)} (see StrictHierarchy).',
    );
    if (!listEquals(_root, next)) {
      final previous = _root;
      _root = next;
      // Collect the new page keys once, shared by result-reconcile and the
      // observer diff (N is tiny, but avoid two identical walks).
      final nextKeys = (_results.isEmpty && _observers.isEmpty)
          ? const <LocalKey>{}
          : tree.collectPageKeys<R>(next);
      if (!_results.isEmpty) {
        _results.reconcileWith(nextKeys);
      }
      notifyListeners();
      if (_observers.isNotEmpty) {
        _notifyObservers(previous, nextKeys);
      }
    } else if (!listEquals(_root, requested)) {
      // The committed stack is unchanged, but the request asked to change it
      // and the pipeline reverted that (e.g. a guard cancelled a system-back
      // removal the framework had already applied via onDidRemovePage). Notify
      // so the delegate rebuilds its pages from `_root` and re-syncs the
      // Navigator, which would otherwise diverge from the source-of-truth tree.
      notifyListeners();
    }
  }

  void _notifyObservers(List<R> previous, Set<LocalKey> nextKeys) {
    final before = tree.collectPageKeys<R>(previous);
    final transition = NavTransition<R>(
      previous: List<R>.unmodifiable(previous),
      next: List<R>.unmodifiable(_root),
      entered: nextKeys.difference(before),
      left: before.difference(nextKeys),
    );
    for (final observer in _observers) {
      observer.onTransition(transition);
    }
  }
}
