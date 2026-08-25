import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart' as meta;

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
  final ListQueue<_QueuedSnapshot<R>> _buffer = ListQueue<_QueuedSnapshot<R>>();
  _QueuedSnapshot<R>? _active;
  Future<void>? _running;
  Future<void>? _observedTrackedDrain;

  /// Whether the queue is currently draining.
  bool get isProcessing => _running != null;

  /// Completes when the active drain becomes idle. Snapshots added before that
  /// happens join the same drain and are included in the returned Future.
  ///
  /// The future completes with the processor's error when a snapshot fails.
  /// It is already complete when the queue is idle.
  Future<void> get processingCompleted =>
      _running ?? SynchronousFuture<void>(null);

  /// Enqueues an immutable copy of [snapshot] and starts draining if idle.
  void add(List<R> snapshot) => _addApplication(snapshot);

  void _addApplication(
    List<R> snapshot, {
    ApplicationNavigationMetadata? metadata,
  }) {
    _buffer.addLast(_QueuedSnapshot<R>.application(snapshot, metadata));
    _startDrain();
  }

  Future<void> _addTracked(
    List<R> snapshot,
    NavigationRequest request,
  ) {
    _buffer.addLast(_QueuedSnapshot<R>.framework(snapshot, request));
    _startDrain();
    _observeTrackedDrain();

    return request.future;
  }

  void _observeTrackedDrain() {
    final drain = _running!;
    if (identical(_observedTrackedDrain, drain)) {
      return;
    }
    _observedTrackedDrain = drain;
    // A framework request exposes its own error Future. Observe the shared
    // drain so the same failure is not reported a second time when application
    // code did not explicitly await processingCompleted.
    unawaited(
      drain.then<void>(
        (_) {},
        onError: (Object _, StackTrace _) {},
      ),
    );
  }

  void _startDrain() {
    // Defer the drain until `_running` holds its Future. Besides making
    // isProcessing immediately accurate, this prevents a synchronously
    // failing processor from completing before the active drain is recorded.
    _running ??= Future<void>.microtask(_drain);
  }

  Future<void> _drain() async {
    try {
      while (_buffer.isNotEmpty) {
        final entry = _buffer.removeFirst();
        _active = entry;
        try {
          await _process(entry.snapshot);
          entry.request?.completeSuccess();
        } on Object catch (error, stackTrace) {
          entry.request?.completeError(error, stackTrace);
          for (final buffered in _buffer) {
            final request = buffered.request;
            if (request == null) {
              buffered.applicationMetadata?.discard();
              continue;
            }
            request.canCommit
                ? request.completeError(error, stackTrace)
                : request.completeAbandoned();
          }
          _buffer.clear();
          Error.throwWithStackTrace(error, stackTrace);
        } finally {
          _active = null;
        }
      }
    } finally {
      _running = null;
    }
  }

  void _sealCommittableTrackedRequests() {
    final activeRequest = _active?.request;
    if (activeRequest != null && activeRequest.canCommit) {
      activeRequest.seal();
    }
    for (final entry in _buffer) {
      final request = entry.request;
      if (request != null && request.canCommit) {
        request.seal();
      }
    }
  }

  List<R>? get _latestEffectiveSnapshot {
    for (final entry in _buffer.toList(growable: false).reversed) {
      if (entry.request?.canCommit ?? true) {
        return entry.snapshot;
      }
    }
    final active = _active;
    if (active != null &&
        !active.passedCommitBoundary &&
        (active.request?.canCommit ?? true)) {
      return active.snapshot;
    }

    return null;
  }
}

final class _QueuedSnapshot<R extends RouteNode> {
  _QueuedSnapshot.application(List<R> snapshot, this.applicationMetadata)
    : snapshot = List<R>.unmodifiable(snapshot),
      request = null;

  _QueuedSnapshot.framework(List<R> snapshot, this.request)
    : snapshot = List<R>.unmodifiable(snapshot),
      applicationMetadata = null;

  final List<R> snapshot;
  final NavigationRequest? request;
  final ApplicationNavigationMetadata? applicationMetadata;
  bool passedCommitBoundary = false;
}

/// Package-internal metadata for one application navigation entry.
///
/// Result effects and Router coordination are deliberately independent. This
/// type is absent from the public barrel and does not expose an app receipt.
@meta.internal
final class ApplicationNavigationMetadata {
  /// Creates metadata consumed only by [RoutesState] and its coordinator.
  ApplicationNavigationMetadata({
    this.effect,
    this.coordinatorContext,
    VoidCallback? onDiscard,
  }) : _onDiscard = onDiscard;

  /// Optional commit-aligned effect such as a `popWith` result.
  final Object? effect;

  /// Opaque context owned by the coordinated Router integration.
  final Object? coordinatorContext;

  final VoidCallback? _onDiscard;
  bool _discarded = false;

  /// Reports fail-fast discard exactly once.
  void discard() {
    if (_discarded) {
      return;
    }
    _discarded = true;
    _onDiscard?.call();
  }
}

/// Package-internal lifecycle for one framework navigation request.
///
/// This type is intentionally absent from `package:rolter/rolter.dart`.
@meta.internal
final class NavigationRequest {
  /// Creates a request whose transaction may become superseded before commit.
  NavigationRequest({
    required this.token,
    required bool Function() canCommit,
    VoidCallback? onSeal,
    VoidCallback? onSuccess,
    VoidCallback? onFailure,
    VoidCallback? onAbandon,
  }) : _canCommit = canCommit,
       _onSeal = onSeal,
       _onSuccess = onSuccess,
       _onFailure = onFailure,
       _onAbandon = onAbandon;

  /// Creates a request that always follows transparent FIFO semantics.
  NavigationRequest.fifo(this.token)
    : _canCommit = _alwaysCommittable,
      _onSeal = null,
      _onSuccess = null,
      _onFailure = null,
      _onAbandon = null;

  /// Opaque identity read only by package integration code.
  final Object token;
  final bool Function() _canCommit;
  final VoidCallback? _onSeal;
  final VoidCallback? _onSuccess;
  final VoidCallback? _onFailure;
  final VoidCallback? _onAbandon;
  final Completer<void> _completer = Completer<void>();
  bool _sealed = false;
  bool _settled = false;

  /// Completion for this request only, never for the shared queue drain.
  Future<void> get future => _completer.future;

  /// Whether this request may still publish its snapshot.
  bool get canCommit => _canCommit();

  /// Makes a currently valid request a FIFO dependency of an app operation.
  void seal() {
    if (_sealed || !_canCommit()) {
      return;
    }
    _sealed = true;
    _onSeal?.call();
  }

  /// Settles an accepted request at its state commit boundary.
  void completeSuccess() {
    if (_settled) {
      return;
    }
    _settled = true;
    _onSuccess?.call();
    _completer.complete();
  }

  /// Settles a superseded or teardown-abandoned request successfully.
  void completeAbandoned() {
    if (_settled) {
      return;
    }
    _settled = true;
    _onAbandon?.call();
    _completer.complete();
  }

  /// Settles a live failed request without wrapping its error.
  void completeError(Object error, StackTrace stackTrace) {
    if (_settled) {
      return;
    }
    _settled = true;
    _onFailure?.call();
    _completer.completeError(error, stackTrace);
  }

  static bool _alwaysCommittable() => true;
}

/// Enqueues one package-internal framework request with its own completion.
@meta.internal
Future<void> enqueueTrackedNavigationSnapshot<R extends RouteNode>(
  NavigationQueue<R> queue,
  List<R> snapshot,
  NavigationRequest request,
) => queue._addTracked(snapshot, request);

/// Enqueues an application snapshot with package-private commit metadata.
@meta.internal
void enqueueApplicationNavigationSnapshot<R extends RouteNode>(
  NavigationQueue<R> queue,
  List<R> snapshot, {
  ApplicationNavigationMetadata? metadata,
}) => queue._addApplication(snapshot, metadata: metadata);

/// Returns the request currently being processed, if framework-tracked.
@meta.internal
NavigationRequest? activeNavigationRequest<R extends RouteNode>(
  NavigationQueue<R> queue,
) => queue._active?.request;

/// Returns package-private metadata attached to the active application entry.
@meta.internal
ApplicationNavigationMetadata? activeApplicationNavigationMetadata<
  R extends RouteNode
>(NavigationQueue<R> queue) => queue._active?.applicationMetadata;

/// Completes the active tracked request at its state commit boundary.
@meta.internal
void completeActiveNavigationRequest<R extends RouteNode>(
  NavigationQueue<R> queue,
) => queue._active?.request?.completeSuccess();

/// Completes an active superseded or teardown-abandoned framework request.
@meta.internal
void abandonActiveNavigationRequest<R extends RouteNode>(
  NavigationQueue<R> queue,
) => queue._active?.request?.completeAbandoned();

/// Excludes an already accepted active snapshot from later relative app bases.
@meta.internal
void markActiveNavigationCommitBoundary<R extends RouteNode>(
  NavigationQueue<R> queue,
) {
  final active = queue._active;
  if (active != null) {
    active.passedCommitBoundary = true;
  }
}

/// Seals current framework requests before an app snapshot depends on them.
@meta.internal
void sealCommittableNavigationRequests<R extends RouteNode>(
  NavigationQueue<R> queue,
) => queue._sealCommittableTrackedRequests();

/// Returns the latest queue snapshot that is still eligible to commit.
@meta.internal
List<R>? latestEffectiveNavigationSnapshot<R extends RouteNode>(
  NavigationQueue<R> queue,
) => queue._latestEffectiveSnapshot;
