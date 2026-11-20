import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/widgets/text_input_sheet.dart';
import '../../../l10n/app_localizations.dart';
import 'groups_providers.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// "Add by name": asks for a name in a sheet and adds a placeholder.
/// Used from the Group screen and Group settings.
Future<void> addPlaceholderFlow(
  BuildContext context,
  WidgetRef ref, {
  required String groupId,
  required String actorMemberId,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final name = await showTextInputSheet(
    context,
    title: l10n.addPlaceholderTitle,
    label: l10n.memberNameLabel,
    helper: l10n.addPlaceholderHelper,
    action: l10n.addButton,
    emptyError: l10n.errorNameRequired,
  );
  if (name == null) return;
  try {
    await ref
        .read(groupRepositoryProvider)
        .addPlaceholder(
          groupId: groupId,
          actorMemberId: actorMemberId,
          name: name,
        );
    messenger.showMessage(l10n.placeholderAdded(name));
  } catch (e) {
    messenger.showMessage(errorText(l10n, e));
  }
}
