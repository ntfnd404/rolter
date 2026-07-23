import '../data_sources/mail_local_data_source.dart';
import '../../domain/entities/mail.dart';
import '../../domain/repositories/mail_repository.dart';

/// [MailRepository] over a [MailLocalDataSource], adding id-lookup on top of the
/// raw source. The source is **injected** by the composition root.
final class MailRepositoryImpl implements MailRepository {
  const MailRepositoryImpl(this._source);

  final MailLocalDataSource _source;

  @override
  List<Mail> all() => _source.fetchAll();

  @override
  Mail? byId(int? id) {
    if (id == null) {
      return null;
    }
    for (final mail in _source.fetchAll()) {
      if (mail.id == id) {
        return mail;
      }
    }
    return null;
  }
}
