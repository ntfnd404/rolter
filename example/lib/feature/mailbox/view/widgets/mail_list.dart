import '../../domain/entities/mail.dart';
import '../../routing/mailbox_nav.dart';
import '../../../../core/routing/app_navigator.dart';
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
