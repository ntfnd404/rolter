import 'package:example/feature/tabbed_stack/shared/domain/repositories/item_repository.dart';
import 'package:example/feature/mailbox/domain/repositories/mail_repository.dart';

/// The app's shared dependencies, wired once in the composition root and read
/// app-wide via `AppScope`.
///
/// Add new shared repositories/services as fields here. For many features,
/// assemble this from per-feature contributions (like the route registry) and
/// build them lazily — rather than one growing hand-written constructor.
class AppDependencies {
  const AppDependencies({
    required this.mailRepository,
    required this.itemRepository,
  });

  final MailRepository mailRepository;
  final ItemRepository itemRepository;
}
