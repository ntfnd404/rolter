/// A mail item — the mailbox feature's domain entity.
class Mail {
  const Mail({
    required this.id,
    required this.from,
    required this.subject,
    required this.body,
  });

  final int id;
  final String from;
  final String subject;
  final String body;
}
