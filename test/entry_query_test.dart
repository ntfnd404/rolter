import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

@immutable
class _Node implements RouteNode {
  const _Node(this.name, {this.params = const {}});

  @override
  final String name;
  final Map<String, String> params;

  @override
  List<RouteNode> get children => const [];

  @override
  LocalKey get pageKey => ValueKey('$name~$params');

  @override
  Map<String, String> toParams() => params;

  @override
  RouteNode withChildren(List<RouteNode> children) => this;

  @override
  Page<Object?> buildPage(BuildContext context) =>
      const MaterialPage(child: SizedBox());
}

void main() {
  final registry = RouteRegistry<_Node>(
    {'a': (p, _) => _Node('a', params: p)},
    fallback: (uri) => const _Node('not-found'),
  );
  final parser = RoutingInformationParser<_Node>(
    TreeUrlCodec<_Node>(registry),
    entryQuery: EntryQueryStore(),
  );

  test('parser captures the entry query into the store', () async {
    final store = parser.entryQuery!;

    await parser.parseRouteInformation(
      RouteInformation(uri: Uri.parse('/a?utm_source=news&id=5')),
    );

    expect(store.value, {'utm_source': 'news', 'id': '5'});
  });

  test('store notifies listeners only on a real change', () {
    final store = EntryQueryStore();
    var fired = 0;
    store.addListener(() => fired++);

    store.capture({'a': '1'});
    store.capture({'a': '1'}); // same -> no notify
    store.capture({'a': '2'});

    expect(fired, 2);
    expect(store.value, {'a': '2'});
  });
}
