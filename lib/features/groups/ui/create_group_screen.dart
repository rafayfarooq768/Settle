import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/ui/profile_providers.dart';
import 'group_type_field.dart';
import 'groups_providers.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// New group: name + free-text type. Works offline; it syncs later.
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _name = TextEditingController();
  final _type = TextEditingController();
  String? _nameError;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _type.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final name = _name.text.trim();
    setState(() {
      _nameError = name.isEmpty ? l10n.errorGroupNameRequired : null;
      _error = null;
    });
    if (name.isEmpty) return;

    final me = ref.read(myIdentityProvider);
    if (me == null) return;
    setState(() => _saving = true);
    try {
      final groupId = await ref
          .read(groupRepositoryProvider)
          .createGroup(
            uid: me.uid,
            name: name,
            type: _type.text.trim(),
            creatorName: me.name,
            paymentMethods: me.paymentMethods,
            phone: me.phone,
          );
      messenger.showMessage(l10n.groupCreated);
      if (mounted) context.pushReplacement('/groups/$groupId');
    } catch (e) {
      if (mounted) setState(() => _error = errorText(l10n, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createGroupTitle)),
      body: ScreenLayout(
        body: [
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.groupNameLabel,
              errorText: _nameError,
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GroupTypeField(controller: _type),
        ],
        actions: [
          if (_error != null) ...[
            FormMessage(_error!),
            const SizedBox(height: AppSpacing.md),
          ],
          LoadingButton(
            label: l10n.createGroupButton,
            isLoading: _saving,
            onPressed: _create,
          ),
        ],
      ),
    );
  }
}
