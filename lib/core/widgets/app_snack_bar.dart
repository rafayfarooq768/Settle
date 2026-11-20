import 'package:material_ui/material_ui.dart';

import '../theme/app_motion.dart';

/// Every SnackBar goes through here so they all close on the same timing
/// (DESIGN.md §7, owner 2026-11-20): 2.5 s, or 4 s when there's Undo.
/// Flutter keeps a SnackBar with an action open until dismissed unless
/// told otherwise, so `persist` is off.
extension AppSnackBar on ScaffoldMessengerState {
  void showMessage(String text, {String? undoLabel, VoidCallback? onUndo}) {
    final undo = undoLabel != null && onUndo != null;
    showSnackBar(
      SnackBar(
        content: Text(text),
        persist: false,
        duration: undo ? AppMotion.undoSnackBar : AppMotion.snackBar,
        action: undo
            ? SnackBarAction(label: undoLabel, onPressed: onUndo)
            : null,
      ),
    );
  }
}
