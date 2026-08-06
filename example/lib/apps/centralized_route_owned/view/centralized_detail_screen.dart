import 'package:flutter/material.dart';

final class CentralizedDetailScreen extends StatelessWidget {
  const CentralizedDetailScreen({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Detail #$id')),
    body: const Center(child: Text('Route-owned Page composition')),
  );
}
