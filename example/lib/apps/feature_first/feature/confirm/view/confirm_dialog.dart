import 'package:flutter/material.dart';

/// Confirmation dialog content shown by a dialog-as-route (`TransparentPage`).
/// A pure view: the route wires [onConfirm]/[onCancel] to `popWith`.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    required this.message,
    required this.onConfirm,
    required this.onCancel,
    super.key,
  });

  final String message;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
        FilledButton(onPressed: onConfirm, child: const Text('Confirm')),
      ],
    );
  }
}
