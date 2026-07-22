import '../routing/mt_tab.dart';
import 'package:flutter/material.dart';

/// Display metadata for [MtTab] — presentation concerns kept out of the identity
/// enum. The label is hardcoded for now; swap each `case` for a localized lookup
/// (e.g. `context.l10n.mtTabInbox`) when the app adds i18n. The icon is not
/// localizable.
extension MtTabPresentation on MtTab {
  IconData get icon => switch (this) {
        MtTab.a => Icons.inbox_outlined,
        MtTab.b => Icons.archive_outlined,
      };

  String get label => switch (this) {
        MtTab.a => 'Inbox',
        MtTab.b => 'Archive',
      };
}
