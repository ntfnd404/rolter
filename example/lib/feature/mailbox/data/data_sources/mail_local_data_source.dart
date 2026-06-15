import 'package:example/feature/mailbox/domain/entities/mail.dart';

/// Local source of mail items — a stand-in for an API or database.
///
/// The repository depends on this interface, not a concrete source, so the data
/// origin can be swapped (in-memory, REST, db) without touching the repository
/// or the UI.
abstract interface class MailLocalDataSource {
  /// All mails, in order.
  List<Mail> fetchAll();
}
