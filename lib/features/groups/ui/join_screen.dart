import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/ui/profile_providers.dart';
import '../domain/join_code.dart';
import 'groups_providers.dart';
import '../../../core/widgets/screen_layout.dart';

/// Join (DESIGN.md §11): code field + "Scan QR". After joining, the Group
/// screen asks "Which one are you?". Needs a connection.
class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  final _code = TextEditingController();
  String? _codeError;
  String? _error;
  bool _joining = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final code = await context.push<String>('/join/scan');
    if (code == null || !mounted) return;
    _code.text = code;
    await _join();
  }

  Future<void> _join() async {
    final l10n = AppLocalizations.of(context)!;
    final code = JoinCode.normalize(_code.text);
    setState(() {
      _codeError = code == null ? l10n.errorCodeFormat : null;
      _error = null;
    });
    final me = ref.read(myIdentityProvider);
    if (code == null || me == null) return;

    setState(() => _joining = true);
    try {
      final repo = ref.read(groupRepositoryProvider);
      final groupId = await repo.findGroupByCode(code);
      if (groupId == null) {
        if (mounted) setState(() => _codeError = l10n.errorCodeNotFound);
        return;
      }
      await repo.join(groupId: groupId, code: code, uid: me.uid);
      if (mounted) context.pushReplacement('/groups/$groupId');
    } catch (e) {
      if (mounted) setState(() => _error = errorText(l10n, e));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.joinTitle)),
      body: ScreenLayout(
        body: [
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _code,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.go,
            textDirection: TextDirection.ltr,
            onSubmitted: (_) => _join(),
            decoration: InputDecoration(
              labelText: l10n.joinCodeLabel,
              hintText: l10n.joinCodeHint,
              errorText: _codeError,
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: LoadingButton(
              label: l10n.scanQrButton,
              onPressed: _joining ? null : _scan,
              style: LoadingButtonStyle.text,
            ),
          ),
        ],
        actions: [
          if (_error != null) ...[
            FormMessage(_error!),
            const SizedBox(height: AppSpacing.md),
          ],
          LoadingButton(
            label: l10n.joinButton,
            isLoading: _joining,
            onPressed: _join,
          ),
        ],
      ),
    );
  }
}
