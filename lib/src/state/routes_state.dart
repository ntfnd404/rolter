import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart' as meta;

import '../model/route_node.dart';
import '../model/route_tree.dart' as tree;
import 'nav_observer.dart';
import 'navigation_queue.dart';
import 'pending_results.dart';

/// Transforms a requested stack into the committed stack — typically normalises
/// it and folds it through guards. May be sync or async; the queue awaits it
/// either way. Framework integrations may submit an equivalent snapshot more
/// than once, so treat each call as a state application rather than a unique
/// user event; side effects must be idempotent or deduplicated externally.
typedef ApplyPipeline<R extends RouteNode> =
    FutureOr<List<R>> Function(
      List<R> requested,
    );

/// Single source of truth for the navigation tree.
///
/// Every intent computes a full target snapshot and enqueues it; the queue
/// commits via [ApplyPipeline] and notifies listeners only on a real change.
/// Navigation mutations throw a [StateError] after [dispose]. An already-active
/// pipeline is not cancelled, but its late result is abandoned without changing
/// state or notifying callbacks.
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
  static const String _disposedMessage = 'RoutesState has been disposed.';
  List<R> _root;
  RoutesStateCoordinator? _coordinator;
  bool _disposed = false;

  /// Committed root stack (read-only view).
  List<R> get root => List<R>.unmodifiable(_root);

  /// Top of the committed stack.
  R get top => _root.last;

  /// Whether the root stack can pop.
  bool get canPop => _root.length > 1;

  /// Whether this state is currently applying queued navigation requests.
  bool get isProcessing => _queue.isProcessing;

  /// Completes when the current active navigation drain becomes idle.
  ///
  /// This lets integrations wait for asynchronous guards to settle without
  /// exposing the internal navigation queue. The returned future represents
  /// the active drain, so it also includes requests added before that drain
  /// becomes idle and may be shared by multiple callers. It is distinct from
  /// the request-scoped Future returned by a `RoutingDelegate` route-path call.
  Future<void> get processingCompleted => _queue.processingCompleted;

  /// Replaces the whole stack with [stack].
  void setRoot(List<R> stack) {
    _ensureActive();
    _enqueueApplication(List<R>.of(stack));
  }

  Future<void> _setFrameworkRoutePath(
    List<R> stack,
    NavigationRequest request,
  ) {
    _ensureActive();
    final snapshot = List<R>.unmodifiable(stack);

    return enqueueTrackedNavigationSnapshot<R>(_queue, snapshot, request);
  }

  /// Pushes [route] onto the stack.
  void push(R route) {
    _ensureActive();
    final base = _applicationBase;
    _enqueueApplication(<R>[...base, route]);
  }

  /// Pops the top of the stack, if more than one node remains.
  void pop() {
    _ensureActive();
    final base = _applicationBase;
    if (base.length > 1) {
      _enqueueApplication(base.sublist(0, base.length - 1));
    }
  }

  /// Replaces the top of the stack with [route].
  void replaceTop(R route) {
    _ensureActive();
    final base = _applicationBase;
    _enqueueApplication(<R>[...base.sublist(0, base.length - 1), route]);
  }

  /// Replaces the whole stack with a single [route].
  void clearAndPush(R route) {
    _ensureActive();
    _enqueueApplication(<R>[route]);
  }

  /// Pushes [route], or replaces the top if it has the same type.
  void pushOrReplaceTop(R route) {
    _ensureActive();
    final base = _applicationBase;
    final target = base.last.runtimeType == route.runtimeType
        ? <R>[...base.sublist(0, base.length - 1), route]
        : <R>[...base, route];
    _enqueueApplication(target);
  }

  /// Removes the node identified by [key] from the stack.
  void removeByPageKey(LocalKey key) {
    _ensureActive();
    final base = _applicationBase;
    final target = tree.removeNodeByKey<R>(base, key);
    _enqueueApplication(target);
  }

  /// Replaces the node at [path] with the result of [transform].
  ///
  /// [transform] is synchronous routing calculation: keep it pure and do not
  /// call navigation APIs from inside it.
  void mutateAt(List<String> path, R Function(R node) transform) {
    _ensureActive();
    final base = _applicationBase;
    final target = tree.mutateNodeAt<R>(base, path, transform);
    _enqueueApplication(target);
  }

  /// Pops from the top until the top satisfies [test] (no-op if none match).
  ///
  /// [test] is synchronous routing calculation: keep it pure and do not call
  /// navigation APIs from inside it.
  void popUntil(bool Function(R node) test) {
    _ensureActive();
    final base = _applicationBase;
    final target = tree.popUntil<R>(base, test);
    _enqueueApplication(target);
  }

  /// Removes every node in the stack that satisfies [test].
  ///
  /// [test] is synchronous routing calculation: keep it pure and do not call
  /// navigation APIs from inside it.
  void removeWhere(bool Function(R node) test) {
    _ensureActive();
    final base = _applicationBase;
    final target = tree.removeWhere<R>(base, test);
    _enqueueApplication(target);
  }

  /// Resets the stack to the topmost node matching [test] (or clears it if none
  /// match), then pushes [route] on top.
  ///
  /// [test] is synchronous routing calculation: keep it pure and do not call
  /// navigation APIs from inside it.
  void pushAndResetTo(R route, bool Function(R node) test) {
    _ensureActive();
    final base = _applicationBase;
    final target = tree.pushAndResetTo<R>(base, route, test);
    _enqueueApplication(target);
  }

  /// Re-applies the effective stack through the pipeline. Wire this to a
  /// `GuardedPipeline.refresh` so guards rerun when their state changes.
  void reevaluate() {
    _ensureActive();
    _enqueueApplication(_applicationBase);
  }

  /// Pushes [route] and completes with the result passed to [popWith], or null
  /// if the route leaves the tree without one (e.g. system back), its enqueue
  /// is discarded after a failure, or this state is disposed. An awaiter must
  /// check its own lifecycle before performing follow-up navigation.
  ///
  /// Results are keyed by [RouteNode.pageKey], so a result route must have a
  /// unique `pageKey` while it is on the stack (the same uniqueness the
  /// Navigator requires of its pages). Pushing a second result route with a
  /// `pageKey` that is already pending is a programming error: it asserts in
  /// debug, and in release the prior awaiter is completed with `null` rather
  /// than leaked.
  Future<T?> pushForResult<T>(R route) {
    _ensureActive();
    final base = _applicationBase;
    final future = _results.register<T>(route.pageKey);
    _enqueueApplication(<R>[...base, route]);

    return future;
  }

  /// Pops the effective top and completes its pending result after commit.
  ///
  /// A guard revert or a live pipeline failure leaves the result pending
  /// because the target route remains committed.
  void popWith<T>(T result) {
    _ensureActive();
    final base = _applicationBase;
    if (base.length <= 1) {
      return;
    }
    final targetKey = base.last.pageKey;
    _enqueueApplication(
      base.sublist(0, base.length - 1),
      effect: _ResultEffect(targetKey, result),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _coordinator?.onRoutesStateDisposed();
    _results.dispose();
    super.dispose();
  }

  List<R> get _applicationBase =>
      latestEffectiveNavigationSnapshot<R>(_queue) ?? _root;

  Object? _beginApplicationNavigation() {
    sealCommittableNavigationRequests<R>(_queue);
    return _coordinator?.beginApplicationNavigation();
  }

  void _enqueueApplication(List<R> target, {Object? effect}) {
    final snapshot = List<R>.unmodifiable(target);
    final coordinator = _coordinator;
    final coordinatorContext = _beginApplicationNavigation();
    enqueueApplicationNavigationSnapshot<R>(
      _queue,
      snapshot,
      metadata: ApplicationNavigationMetadata(
        effect: effect,
        coordinatorContext: coordinatorContext,
        onDiscard: coordinator == null
            ? null
            : () => coordinator.failApplicationNavigation(
                coordinatorContext,
              ),
      ),
    );
  }

  Future<void> _commit(List<R> requested) async {
    final request = activeNavigationRequest<R>(_queue);
    if (_disposed || (request != null && !request.canCommit)) {
      abandonActiveNavigationRequest<R>(_queue);
      return;
    }
    try {
      final applied = await _pipeline(requested);
      if (_disposed || (request != null && !request.canCommit)) {
        abandonActiveNavigationRequest<R>(_queue);
        return;
      }

      final next = List<R>.of(applied);
      _validateTree(next);
      if (_disposed || (request != null && !request.canCommit)) {
        abandonActiveNavigationRequest<R>(_queue);
        return;
      }

      final changed = !listEquals(_root, next);
      final needsResync = !changed && !listEquals(_root, requested);
      final applicationMetadata = activeApplicationNavigationMetadata<R>(
        _queue,
      );
      final effect = applicationMetadata?.effect;
      final needsKeys = !_results.isEmpty || _observers.isNotEmpty;
      final nextKeys = needsKeys
          ? tree.collectPageKeys<R>(next)
          : const <LocalKey>{};
      final transition = changed && _observers.isNotEmpty
          ? _createTransition(_root, next, nextKeys)
          : null;

      if (_disposed || (request != null && !request.canCommit)) {
        abandonActiveNavigationRequest<R>(_queue);
        return;
      }

      markActiveNavigationCommitBoundary<R>(_queue);

      // The request Completer is deliberately asynchronous. Completing it
      // immediately before this synchronous publication satisfies Flutter's
      // RouterDelegate contract while ensuring callbacks observe the new root.
      completeActiveNavigationRequest<R>(_queue);

      if (changed) {
        _root = next;
      }

      if (!_results.isEmpty) {
        _reconcileResultsAfterCommit(effect, nextKeys);
      }

      if (request == null) {
        _coordinator?.completeApplicationNavigation(
          applicationMetadata?.coordinatorContext,
          changed: changed,
          needsResync: needsResync,
        );
      }

      if (changed) {
        notifyListeners();
        if (transition != null) {
          _notifyObservers(transition);
        }
      } else if (needsResync) {
        notifyListeners();
      }
    } on Object catch (error, stackTrace) {
      if (_disposed || (request != null && !request.canCommit)) {
        abandonActiveNavigationRequest<R>(_queue);
        return;
      }

      final applicationMetadata = activeApplicationNavigationMetadata<R>(
        _queue,
      );
      if (request == null) {
        _coordinator?.failApplicationNavigation(
          applicationMetadata?.coordinatorContext,
        );
      }

      // Buffered work is discarded by NavigationQueue. Reconcile speculative
      // result registrations against the only committed source of truth while
      // preserving results for routes that are still present.
      if (!_results.isEmpty) {
        _reconcileResultsAfterFailure();
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void _reconcileResultsAfterCommit(Object? effect, Set<LocalKey> nextKeys) {
    try {
      if (effect case final _ResultEffect resultEffect
          when !nextKeys.contains(resultEffect.key)) {
        _results.complete(resultEffect.key, resultEffect.value);
      }
      _results.reconcileWith(nextKeys);
    } on Object catch (error, stackTrace) {
      // The route tree is already committed. A broken application-owned key
      // must not roll that commit back or fail an already-completed framework
      // request.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'rolter',
          context: ErrorDescription(
            'while reconciling navigation results after a commit',
          ),
        ),
      );
    }
  }

  void _reconcileResultsAfterFailure() {
    try {
      _results.reconcileWith(tree.collectPageKeys<R>(_root));
    } on Object catch (error, stackTrace) {
      // Cleanup must not replace the causal pipeline/validation error.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'rolter',
          context: ErrorDescription(
            'while reconciling navigation results after a failed drain',
          ),
        ),
      );
    }
  }

  NavTransition<R> _createTransition(
    List<R> previous,
    List<R> next,
    Set<LocalKey> nextKeys,
  ) {
    final before = tree.collectPageKeys<R>(previous);

    return NavTransition<R>(
      previous: List<R>.unmodifiable(previous),
      next: List<R>.unmodifiable(next),
      entered: Set<LocalKey>.unmodifiable(nextKeys.difference(before)),
      left: Set<LocalKey>.unmodifiable(before.difference(nextKeys)),
    );
  }

  void _notifyObservers(NavTransition<R> transition) {
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
        'rolter: the committed stack has a duplicate pageKey. '
        'Every RouteNode.pageKey must be unique across '
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

  void _ensureActive() {
    if (_disposed) {
      throw StateError(_disposedMessage);
    }
  }

  void _attachCoordinator(RoutesStateCoordinator coordinator) {
    _ensureActive();
    if (_coordinator != null) {
      throw StateError(
        'RoutesState already has an active RoutingConfig.',
      );
    }
    _coordinator = coordinator;
  }

  void _detachCoordinator(RoutesStateCoordinator coordinator) {
    if (identical(_coordinator, coordinator)) {
      _coordinator = null;
    }
  }
}

final class _ResultEffect {
  const _ResultEffect(this.key, this.value);

  final LocalKey key;
  final Object? value;
}

/// Package-internal bridge used by the coordinated Router configuration.
@meta.internal
abstract interface class RoutesStateCoordinator {
  /// Starts a temporal FIFO barrier for an app entry that will be enqueued.
  Object? beginApplicationNavigation();

  /// Records the observable outcome of an active application entry.
  void completeApplicationNavigation(
    Object? context, {
    required bool changed,
    required bool needsResync,
  });

  /// Records active failure or buffered fail-fast discard of an app entry.
  void failApplicationNavigation(Object? context);

  /// Prevents late parser/delegate work after state-first teardown.
  void onRoutesStateDisposed();
}

/// Enqueues one framework route-path request and returns its own completion.
@meta.internal
Future<void> applyFrameworkRoutePath<R extends RouteNode>(
  RoutesState<R> state,
  List<R> configuration,
  NavigationRequest request,
) => state._setFrameworkRoutePath(configuration, request);

/// Returns the active framework request for package integration code.
@meta.internal
NavigationRequest? activeFrameworkRouteRequest<R extends RouteNode>(
  RoutesState<R> state,
) => activeNavigationRequest<R>(state._queue);

/// Whether the backing state has already been disposed.
@meta.internal
bool routesStateIsDisposed<R extends RouteNode>(RoutesState<R> state) =>
    state._disposed;

/// Attaches the single active coordinated Router integration.
@meta.internal
void attachRoutesStateCoordinator<R extends RouteNode>(
  RoutesState<R> state,
  RoutesStateCoordinator coordinator,
) => state._attachCoordinator(coordinator);

/// Detaches a coordinated Router integration without disposing the state.
@meta.internal
void detachRoutesStateCoordinator<R extends RouteNode>(
  RoutesState<R> state,
  RoutesStateCoordinator coordinator,
) => state._detachCoordinator(coordinator);
