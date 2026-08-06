import '../entities/mail.dart';

/// Reads mail items. The contract lives in `domain/`; the UI depends on this,
/// not on a concrete source or impl.
abstract interface class MailRepository {
  /// All mails, in order.
  List<Mail> all();

  /// The mail with [id], or `null` if there is none (or [id] is `null`).
  Mail? byId(int? id);
}
