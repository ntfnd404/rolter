import '../domain/repositories/mail_repository.dart';
import '../view/mailbox_screen.dart';
import '../../../composition/app_route_page_catalog.dart';
import 'package:flutter/material.dart';

import '../routing/mailbox_route.dart';

/// Creates the mailbox page contribution with its narrow data dependency.
AppRoutePageDefinition buildMailboxPageDefinition({
  required MailRepository repository,
}) => TypedAppRoutePageDefinition<MailboxRoute>(
  pageFactory: (context, route, nestedPageBuilder) => MaterialPage<Object?>(
    key: route.pageKey,
    name: route.name,
    child: MailboxScreen(repository: repository, selectedId: route.selectedId),
  ),
);
