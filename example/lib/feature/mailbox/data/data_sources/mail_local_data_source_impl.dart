import 'mail_local_data_source.dart';
import '../../domain/entities/mail.dart';

/// In-memory [MailLocalDataSource] holding a fixed demo data set.
final class MailLocalDataSourceImpl implements MailLocalDataSource {
  const MailLocalDataSourceImpl();

  static const List<Mail> _mails = [
    Mail(
      id: 1,
      from: 'Alice',
      subject: 'Welcome aboard',
      body: 'Thanks for trying rolter routing.',
    ),
    Mail(
      id: 2,
      from: 'Bob',
      subject: 'Lunch today?',
      body: 'Are you free around noon?',
    ),
    Mail(
      id: 3,
      from: 'Carol',
      subject: 'Quarterly report',
      body: 'The numbers are looking great.',
    ),
  ];

  @override
  List<Mail> fetchAll() => _mails;
}
