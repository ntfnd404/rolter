import 'package:example/feature/mailbox/routing/mailbox_route.dart';
import 'package:example/feature/mailbox/routing/mailbox_route_name.dart';
import 'package:example/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Mailbox feature's decoder contribution to the app registry.
Map<String, RouteDecoder<AppRoute>> get mailboxRoutes => {
  MailboxRouteName.mailbox.wire: (params, _) =>
      MailboxRoute(selectedId: int.tryParse(params['sel'] ?? '')),
};
