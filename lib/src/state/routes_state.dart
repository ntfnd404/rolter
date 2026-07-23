import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/route_node.dart';
import '../model/route_tree.dart' as tree;
import 'nav_observer.dart';
import 'navigation_queue.dart';
import 'pending_results.dart';

/// Transforms a requested stack into the committed stack — typically normalises
/// it and folds it through guards. May be sync or async; the queue awaits it
/// either way.
typedef ApplyPipeline<R extends RouteNode> =
    FutureOr<List<R>> Function(
      List<R> requested,
    );

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
    _validateTree(_root);
    _observers = List<NavObserver<R>>.unmodifiable(observers);
    _queue = NavigationQueue<R>(_commit);
  }
  final ApplyPipeline<R> _pipeline;
  late final List<NavObserver<R>> _observers;
  final PendingResults _results = PendingResults();
  late final NavigationQueue<R> _queue;
  List<R> _root;
  List<R>? _pending;
  int _pendingRequestCount = 0;

  /// Committed root stack (read-only view).
  List<R> get root => List<R>.unmodifiable(_root);

  /// Top of the committed stack.
  R get top => _root.last;

  /// Whether the root stack can pop.
  bool get canPop => _root.length > 1;

  /// Whether this state is currently applying queued navigation requests.
  bool get isProcessing => _queue.isProcessing;

  /// Completes when all navigation requests queued so far have been processed.
  ///
  /// This lets integrations wait for asynchronous guards to settle without
  /// exposing the internal navigation queue.
  Future<void> get processingCompleted => _queue.processingCompleted;

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
    final snapshot = List<R>.unmodifiable(target);
    _pending = snapshot;
    _pendingRequestCount++;
    _queue.add(snapshot);
  }

  Future<void> _commit(List<R> requested) async {
    try {
      final next = List<R>.of(await _pipeline(requested));
      _validateTree(next);
      assert(_pendingRequestCount > 0);
      _pendingRequestCount--;
      if (_pendingRequestCount == 0) {
        _pending = null;
      }
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
        // removal the framework had already applied via onDidRemovePage).
        // Notify so the delegate rebuilds its pages from `_root` and re-syncs
        // the Navigator, which would otherwise diverge from the source-of-truth
        // tree.
        notifyListeners();
      }
    } catch (_) {
      // NavigationQueue discards snapshots behind any failed commit. Reset the
      // speculative base for failures in the pipeline or later commit work, so
      // recovery always starts from the actual committed state.
      _pending = null;
      _pendingRequestCount = 0;
      rethrow;
    }
  }

  void _notifyObservers(List<R> previous, Set<LocalKey> nextKeys) {
    final before = tree.collectPageKeys<R>(previous);
    final transition = NavTransition<R>(
      previous: List<R>.unmodifiable(previous),
      next: List<R>.unmodifiable(_root),
      entered: Set<LocalKey>.unmodifiable(nextKeys.difference(before)),
      left: Set<LocalKey>.unmodifiable(before.difference(nextKeys)),
    );
    for (final observer in _observers) {
      try {
        observer.onTransition(transition);
      } catch (error, stackTrace) {
        // Telemetry is deliberately isolated from the navigation transaction:
        // one faulty observer must not abort the queue or suppress later
        // observers after the route state has already committed.
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'rolter',
            context: ErrorDescription('while notifying a NavObserver'),
          ),
        );
      }
    }
  }

  void _validateTree(List<R> roots) {
    final duplicatePageKey = tree.firstDuplicatePageKey<R>(roots);
    if (duplicatePageKey != null) {
      throw StateError(
        'rolter: the committed stack has a duplicate pageKey '
        '($duplicatePageKey). Every RouteNode.pageKey must be unique across '
        'the whole tree — encode identity-bearing params into pageKey '
        '(see RouteNode.pageKey).',
      );
    }
    assert(() {
      final hierarchyViolation = tree.hierarchyViolation<R>(roots);
      assert(
        hierarchyViolation == null,
        'rolter: strict-hierarchy violation in the committed stack — '
        '$hierarchyViolation (see StrictHierarchy).',
      );

      return true;
    }());
  }
}
