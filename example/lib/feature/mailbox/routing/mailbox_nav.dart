import 'package:example/feature/mailbox/routing/mailbox_route.dart';
import 'package:example/routing/app_navigator.dart';

/// Mailbox feature's navigation sugar, added to the shared [AppNavigator].
extension MailboxNav on AppNavigator {
  void toMailbox() => push(const MailboxRoute());

  void selectMail(int id) => replaceTop(MailboxRoute(selectedId: id));

  void deselectMail() => replaceTop(const MailboxRoute());
}
