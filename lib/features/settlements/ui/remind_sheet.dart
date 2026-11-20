import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_links.dart';
import '../../../core/phone/phone_number.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// WhatsApp reminder (PLAN.md §3 item 11): a prefilled message you can
/// edit, sent through a wa.me link (no API). With the person's [phone] it
/// opens their chat; without one, WhatsApp asks who to send it to.
Future<void> showRemindSheet(
  BuildContext context, {
  required String title,
  required String message,
  String phone = '',
}) => showAppSheet<void>(
  context: context,
  scrollControlled: true,
  builder: (_) => _RemindSheet(title: title, message: message, phone: phone),
);

class _RemindSheet extends StatefulWidget {
  const _RemindSheet({
    required this.title,
    required this.message,
    required this.phone,
  });

  final String title;
  final String message;
  final String phone;

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
    final text = _text.text.trim();
    final digits = whatsAppDigits(widget.phone);
    final opened = await launchUrl(
      digits == null
          ? AppLinks.whatsAppShare(text)
          : AppLinks.whatsAppTo(digits, text),
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
            // Where it goes, so nobody is surprised by the chat that opens.
            Text(
              whatsAppDigits(widget.phone) == null
                  ? l10n.remindPickChat
                  : l10n.remindSendsTo(formatPhone(widget.phone)),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
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
