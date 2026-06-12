import 'package:example/feature/mailbox/data/mail_item.dart';
import 'package:flutter/material.dart';

class MailDetail extends StatelessWidget {
  const MailDetail({super.key, required this.mail});

  final MailItem? mail;

  @override
  Widget build(BuildContext context) {
    final current = mail;
    if (current == null) {
      return const Center(child: Text('Select a mail to read it.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(current.subject, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'From ${current.from}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(current.body),
        ],
      ),
    );
  }
}
