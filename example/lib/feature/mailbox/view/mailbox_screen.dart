import 'package:example/core/di/app_scope.dart';
import 'package:example/feature/mailbox/routing/mailbox_nav.dart';
import 'package:example/feature/mailbox/view/widgets/mail_detail.dart';
import 'package:example/feature/mailbox/view/widgets/mail_list.dart';
import 'package:example/feature/mailbox/view/widgets/mailbox_constants.dart';
import 'package:example/core/routing/app_navigator.dart';
import 'package:flutter/material.dart';

/// Master-detail screen driven by the URL.
///
/// Wide windows show the list and the detail in one [Row] under a single
/// (shared) AppBar; narrow windows show the list, or the detail when a mail is
/// selected. Selection is `MailboxRoute.selectedId`, so it is in the URL and
/// survives a refresh. Mail data comes from a [MailRepository].
class MailboxScreen extends StatelessWidget {
  const MailboxScreen({required this.selectedId, super.key});

  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    final repository = AppScope.of(context).mailRepository;
    final mails = repository.all();
    final selected = repository.byId(selectedId);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= MailboxConstants.splitBreakpoint) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mailbox — split')),
            body: Row(
              children: [
                SizedBox(
                  width: 280,
                  child: MailList(mails: mails, selectedId: selectedId),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: MailDetail(mail: selected)),
              ],
            ),
          );
        }

        if (selected != null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(selected.subject),
              leading: BackButton(
                onPressed: () => context.navigator.deselectMail(),
              ),
            ),
            body: MailDetail(mail: selected),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Mailbox')),
          body: MailList(mails: mails, selectedId: selectedId),
        );
      },
    );
  }
}
