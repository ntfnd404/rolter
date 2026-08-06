import 'package:example/common/ui/demo_home_content.dart';
import 'package:example/common/ui/demo_item_detail_content.dart';
import 'package:example/common/ui/demo_item_view_data.dart';
import 'package:example/common/ui/demo_items_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('common Home delegates navigation through a callback', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: DemoHomeContent(
          approach: 'test approach',
          onOpenItems: () => calls++,
        ),
      ),
    );

    await tester.tap(find.text('Browse demo items'));
    expect(calls, 1);
  });

  testWidgets('common catalog content renders values and delegates identity', (
    tester,
  ) async {
    const item = DemoItemViewData(
      id: 7,
      title: 'Shared item',
      description: 'Presentation only',
    );
    int? selectedId;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DemoItemsContent(
            items: const [item],
            onOpenItem: (id) => selectedId = id,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Shared item'));
    expect(selectedId, 7);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DemoItemDetailContent(item: item)),
      ),
    );
    expect(find.byKey(const ValueKey('demo-item-detail-7')), findsOneWidget);
  });
}
