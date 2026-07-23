import 'mailbox_route_name.dart';
import '../view/mailbox_screen.dart';
import '../../../core/routing/app_route.dart';
import 'package:flutter/material.dart';

/// Master-detail route. [selectedId] lives in the URL (`~sel=N`), so the
/// selection survives a refresh and is deep-linkable. The page key is stable,
/// so changing the selection updates the same page (the split view rebuilds its
/// detail pane) instead of pushing a new one — equality folds in [selectedId].
final class MailboxRoute extends AppRoute {
  const MailboxRoute({this.selectedId});

  final int? selectedId;

  @override
  LocalKey get pageKey => const ValueKey('mailbox');

  @override
  String get name => MailboxRouteName.mailbox.wire;

  @override
  Map<String, String> toParams() =>
      selectedId == null ? const {} : {'sel': '$selectedId'};

  @override
  Page<Object?> buildPage(BuildContext context) => MaterialPage(
    key: pageKey,
    child: MailboxScreen(selectedId: selectedId),
  );

  @override
  int get hashCode => Object.hash(MailboxRoute, selectedId);

  @override
  bool operator ==(Object other) =>
      other is MailboxRoute && other.selectedId == selectedId;
}
