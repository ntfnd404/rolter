import 'package:flutter/material.dart';

import '../../../common/ui/demo_item_detail_content.dart';
import '../../../common/ui/demo_item_view_data.dart';

final class CentralizedItemDetailScreen extends StatelessWidget {
  const CentralizedItemDetailScreen({required this.item, super.key});

  final DemoItemViewData item;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Item #${item.id}')),
    body: DemoItemDetailContent(item: item),
  );
}
