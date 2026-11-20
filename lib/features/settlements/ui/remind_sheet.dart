import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_links.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// WhatsApp reminder (PLAN.md §3 item 11): a prefilled message you can
/// edit, sent through a wa.me link. No API, no phone numbers stored:
/// WhatsApp asks who to send it to.
Future<void> showRemindSheet(
  BuildContext context, {
  required String title,
  required String message,
}) => showAppSheet<void>(
  context: context,
  scrollControlled: true,
  builder: (_) => _RemindSheet(title: title, message: message),
);

class _RemindSheet extends StatefulWidget {
  const _RemindSheet({required this.title, required this.message});

  final String title;
  final String message;

  @override
  State<_RemindSheet> createState() => _RemindSheetState();
}

class _RemindSheetState extends State<_RemindSheet> {
  late final _text = TextEditingController(text: widget.message);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final opened = await launchUrl(
      AppLinks.whatsAppShare(_text.text.trim()),
      mode: LaunchMode.externalApplication,
    );
    if (opened) {
      navigator.pop();
    } else {
      messenger.showMessage(l10n.errorOpenWhatsApp);
    }
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
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetTitle(widget.title, inset: false),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _text,
              minLines: 3,
              maxLines: 6,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.remindMessageLabel,
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ValueListenableBuilder(
              valueListenable: _text,
              builder: (context, value, _) => LoadingButton(
                label: l10n.remindSendButton,
                onPressed: value.text.trim().isEmpty ? null : _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
