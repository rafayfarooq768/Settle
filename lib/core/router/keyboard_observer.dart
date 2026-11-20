import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Keeps the keyboard closed when something on top closes.
///
/// When a sheet, dialog, date picker or screen closes, Flutter gives focus
/// back to the text field that had it before, and the keyboard opens again
/// although nobody tapped the field (owner, 2026-11-20: only a tap on the
/// field should open it). Flutter hands focus back in a microtask queued
/// before observers hear about the close; the one queued here runs right
/// after it, before the next frame, and lets go of that field again.
/// Tapping a field still opens the keyboard, and autofocus on a newly
/// opened screen is untouched (that's a push, not a pop).
class KeyboardStaysClosedObserver extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _releaseTextField();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _releaseTextField();

  void _releaseTextField() {
    scheduleMicrotask(() {
      final focused = FocusManager.instance.primaryFocus;
      final context = focused?.context;
      if (context == null) return;
      // Only a text field; buttons and other focus stay as they are.
      if (context.findAncestorStateOfType<EditableTextState>() == null) return;
      focused!.unfocus();
    });
  }
}
