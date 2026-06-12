import 'package:flutter/material.dart';

/// Flat pushed screen with a typed [id] param. Deep-linkable as
/// `/home/detail~id=5`.
class DetailScreen extends StatelessWidget {
  const DetailScreen({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail #$id')),
      body: Center(child: Text('Typed param id=$id — survives a refresh.')),
    );
  }
}
