import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/group.dart';
import 'group_type_field.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/app_sheet.dart';

typedef GroupEdit = ({String name, String type});

/// Edit name and type in a bottom sheet. Returns null if cancelled.
Future<GroupEdit?> showEditGroupSheet(BuildContext context, Group group) =>
    showAppSheet<GroupEdit>(
      context: context,
      scrollControlled: true,
      builder: (context) => _EditGroupSheet(group: group),
    );

class _EditGroupSheet extends StatefulWidget {
  const _EditGroupSheet({required this.group});

  final Group group;

  @override
  State<_EditGroupSheet> createState() => _EditGroupSheetState();
}

class _EditGroupSheetState extends State<_EditGroupSheet> {
  late final _name = TextEditingController(text: widget.group.name);
  late final _type = TextEditingController(text: widget.group.type);
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _type.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(
        () => _nameError = AppLocalizations.of(context)!.errorGroupNameRequired,
      );
      return;
    }
    Navigator.of(context).pop((name: name, type: _type.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: AppSpacing.screenHorizontal,
        end: AppSpacing.screenHorizontal,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetTitle(l10n.editGroupTitle, inset: false),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _name,
              maxLength: 60,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.groupNameLabel,
                errorText: _nameError,
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GroupTypeField(controller: _type),
            const SizedBox(height: AppSpacing.xl),
            LoadingButton(label: l10n.saveButton, onPressed: _save),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancelButton),
            ),
          ],
        ),
      ),
    );
  }
}
