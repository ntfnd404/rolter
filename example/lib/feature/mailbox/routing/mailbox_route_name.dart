/// Wire names for the Mailbox feature's routes.
enum MailboxRouteName {
  mailbox('mailbox');

  const MailboxRouteName(this.wire);

  /// URL segment and registry key.
  final String wire;
}
