import 'package:example/feature/mailbox/routing/mailbox_nav.dart';
import 'package:example/routing/app_navigator.dart';
import 'package:flutter/material.dart';

/// Width at or above which the mailbox shows list and detail side by side.
const double _splitBreakpoint = 600;

/// A demo mail item.
class MailItem {
  const MailItem(this.id, this.from, this.subject, this.body);

  final int id;
  final String from;
  final String subject;
  final String body;
}

const List<MailItem> _mails = [
  MailItem(1, 'Alice', 'Welcome aboard', 'Thanks for trying rolter routing.'),
  MailItem(2, 'Bob', 'Lunch today?', 'Are you free around noon?'),
  MailItem(3, 'Carol', 'Quarterly report', 'The numbers are looking great.'),
];

MailItem? _mailById(int? id) {
  if (id == null) {
    return null;
  }
  for (final mail in _mails) {
    if (mail.id == id) {
      return mail;
    }
  }
  return null;
}

/// Master-detail screen driven by the URL.
///
/// Wide windows show the list and the detail in one [Row] under a single
/// (shared) AppBar; narrow windows show the list, or the detail when a mail is
/// selected. Selection is `MailboxRoute.selectedId`, so it is in the URL and
/// survives a refresh.
class MailboxScreen extends StatelessWidget {
  const MailboxScreen({required this.selectedId, super.key});

  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _splitBreakpoint) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mailbox — split')),
            body: Row(
              children: [
                SizedBox(width: 280, child: _MailList(selectedId: selectedId)),
                const VerticalDivider(width: 1),
                Expanded(child: _MailDetail(mail: _mailById(selectedId))),
              ],
            ),
          );
        }

        final selected = _mailById(selectedId);
        if (selected != null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(selected.subject),
              leading: BackButton(
                onPressed: () => context.navigator.deselectMail(),
              ),
            ),
            body: _MailDetail(mail: selected),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Mailbox')),
          body: _MailList(selectedId: selectedId),
        );
      },
    );
  }
}

class _MailList extends StatelessWidget {
  const _MailList({required this.selectedId});

  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final mail in _mails)
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

class _MailDetail extends StatelessWidget {
  const _MailDetail({required this.mail});

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
