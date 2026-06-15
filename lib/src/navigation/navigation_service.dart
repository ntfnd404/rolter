import 'package:rolter/src/model/route_node.dart';

/// The navigation surface that app code (screens, scopes) depends on.
///
/// Wide enough to cover what the app actually uses — push / replace / clear
/// plus nested mutation and result-returning push — so it is a genuine seam
/// (a later swap to a different engine needs no screen rewrites), not a
/// two-method token.
abstract interface class NavigationService<R extends RouteNode> {
  /// Whether the active stack can pop.
  bool get canPop;

  /// The current root stack (read-only). Used by nested hosts to read their
  /// subtree without depending on the concrete state.
  List<R> get rootStack;

  /// Pops the top of the active stack.
  void pop();

  /// Pushes [route] onto the root stack.
  void push(R route);

  /// Replaces the top of the root stack with [route].
  void replaceTop(R route);

  /// Resets the root stack to a single [route].
  void clearAndPush(R route);

  /// Replaces the top if it has the same runtime type as [route], else pushes.
  void pushOrReplaceTop(R route);

  /// Pops from the top until the top satisfies [test] (no-op if none match).
  void popUntil(bool Function(R node) test);

  /// Removes every node in the active stack that satisfies [test].
  void removeWhere(bool Function(R node) test);

  /// Resets the stack to the topmost node matching [test] (or clears it if none
  /// match), then pushes [route] on top.
  void pushAndResetTo(R route, bool Function(R node) test);

  /// Transforms the node at [path] in the tree (nested navigation).
  void mutateAt(List<String> path, R Function(R node) transform);

  /// Pushes [route] and completes when it is popped — with the value passed to
  /// [popWith], or null if it leaves the tree without one (e.g. system back).
  Future<T?> pushForResult<T>(R route);

  /// Completes the active route's pending result with [result] and pops it.
  void popWith<T>(T result);
}
