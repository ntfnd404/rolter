import 'package:rolter/src/model/route_node.dart';
import 'package:rolter/src/navigation/navigation_service.dart';
import 'package:rolter/src/state/routes_state.dart';

/// Default [NavigationService] over a [RoutesState]. App-specific typed sugar
/// (e.g. `AppNavigator.toHome`) extends this.
class NavigationController<R extends RouteNode>
    implements NavigationService<R> {
  /// Creates a controller backed by [_state].
  const NavigationController(this._state);
  final RoutesState<R> _state;

  @override
  bool get canPop => _state.canPop;

  @override
  List<R> get rootStack => _state.root;

  @override
  void pop() => _state.pop();

  @override
  void push(R route) => _state.push(route);

  @override
  void replaceTop(R route) => _state.replaceTop(route);

  @override
  void clearAndPush(R route) => _state.clearAndPush(route);

  @override
  void pushOrReplaceTop(R route) => _state.pushOrReplaceTop(route);

  @override
  void popUntil(bool Function(R node) test) => _state.popUntil(test);

  @override
  void removeWhere(bool Function(R node) test) => _state.removeWhere(test);

  @override
  void pushAndResetTo(R route, bool Function(R node) test) =>
      _state.pushAndResetTo(route, test);

  @override
  void mutateAt(List<String> path, R Function(R node) transform) =>
      _state.mutateAt(path, transform);

  @override
  Future<T?> pushForResult<T>(R route) => _state.pushForResult<T>(route);

  @override
  void popWith<T>(T result) => _state.popWith<T>(result);
}
