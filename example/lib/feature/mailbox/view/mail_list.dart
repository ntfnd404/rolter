import 'package:example/feature/mailbox/domain/entities/mail.dart';
import 'package:example/feature/mailbox/routing/mailbox_nav.dart';
import 'package:example/routing/app_navigator.dart';
import 'package:flutter/material.dart';

class MailList extends StatelessWidget {
  const MailList({super.key, required this.mails, required this.selectedId});

  final List<Mail> mails;
  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final mail in mails)
          ListTile(
            selected: mail.id == selectedId,
            leading: const Icon(Icons.mail_outline),
            title: Text(mail.subject),
            subtitle: Text(mail.from),
            onTap: () => context.navigator.selectMail(mail.id),
          ),
      ],
    );
  }
}
