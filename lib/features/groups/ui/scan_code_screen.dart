import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/join_code.dart';

/// Scans a group's QR and pops with the join code. On-device scanning
/// (Google Play services), no paid API.
class ScanCodeScreen extends StatefulWidget {
  const ScanCodeScreen({super.key});

  @override
  State<ScanCodeScreen> createState() => _ScanCodeScreenState();
}

class _ScanCodeScreenState extends State<ScanCodeScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final code = JoinCode.normalize(barcode.rawValue ?? '');
      if (code != null) {
        _done = true;
        Navigator.of(context).pop(code);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanTitle)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: Text(l10n.scanHint),
            ),
            Expanded(
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                errorBuilder: (context, error) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                  child: Text(
                    error.errorCode == MobileScannerErrorCode.permissionDenied
                        ? l10n.errorCameraDenied
                        : l10n.errorCamera,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
