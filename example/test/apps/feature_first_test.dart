import 'package:example/apps/feature_first/feature_first_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the complete feature-first enterprise showcase', (
    tester,
  ) async {
    await tester.pumpWidget(const FeatureFirstExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('rolter example'), findsOneWidget);
    expect(find.text('Mailbox (master-detail)'), findsOneWidget);
    expect(find.text('Multi-tab independent stacks'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reuses the existing nested Items flow as the comparison flow', (
    tester,
  ) async {
    await tester.pumpWidget(const FeatureFirstExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Browse demo items'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('demo-items-content')), findsOneWidget);

    await tester.tap(find.text('Item #1'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('demo-item-detail-1')), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('demo-items-content')), findsOneWidget);
  });
}
