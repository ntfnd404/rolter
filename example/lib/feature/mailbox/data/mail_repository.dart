import 'package:example/feature/mailbox/data/mail_item.dart';

/// In-memory demo source of mail items.
///
/// A stand-in for a real data layer (API/db); the screen depends on this rather
/// than hardcoding the list, so the data can be swapped without touching the UI.
class MailRepository {
  const MailRepository();

  static const List<MailItem> _mails = [
    MailItem(1, 'Alice', 'Welcome aboard', 'Thanks for trying rolter routing.'),
    MailItem(2, 'Bob', 'Lunch today?', 'Are you free around noon?'),
    MailItem(3, 'Carol', 'Quarterly report', 'The numbers are looking great.'),
  ];

  /// All mails, in order.
  List<MailItem> all() => _mails;

  /// The mail with [id], or `null` if there is none (or [id] is `null`).
  MailItem? byId(int? id) {
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
}
