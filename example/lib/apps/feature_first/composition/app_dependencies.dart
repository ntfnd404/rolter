import 'package:flutter/foundation.dart';

import '../feature/mailbox/domain/repositories/mail_repository.dart';
import '../feature/tabbed_stack/shared/domain/repositories/item_repository.dart';

/// The app's shared dependencies, wired once in the composition root.
///
/// The page catalog passes each feature only the repository or service it
/// needs. Add new shared dependencies here, then narrow them in `app_pages.dart`
/// rather than making this whole container available to leaf widgets.
@immutable
final class AppDependencies {
  const AppDependencies({
    required this.mailRepository,
    required this.itemRepository,
  });

  final MailRepository mailRepository;
  final ItemRepository itemRepository;
}
