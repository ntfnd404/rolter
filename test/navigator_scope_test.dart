import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

void main() {
  testWidgets('returns the exact stable navigator across consumer rebuilds', (
    tester,
  ) async {
    final navigator = Object();
    var builds = 0;
    Object? observed;
    late StateSetter rebuild;

    await tester.pumpWidget(
      NavigatorScope<Object>(
        navigator: navigator,
        child: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            builds++;
            observed = NavigatorScope.of<Object>(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(observed, same(navigator));
    expect(builds, 1);

    rebuild(() {});
    await tester.pump();

    expect(observed, same(navigator));
    expect(builds, 2);
  });

  testWidgets('missing lookup fails without exposing widget values', (
    tester,
  ) async {
    late FlutterError error;

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          try {
            NavigatorScope.of<Object>(context);
          } on FlutterError catch (caught) {
            error = caught;
          }
          return const SizedBox();
        },
      ),
    );

    expect(error.message, contains('NavigatorScope<Object> not found'));
  });
}
