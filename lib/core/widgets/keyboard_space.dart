import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Makes room for the keyboard the moment a text field gets focus.
///
/// Some keyboards (Samsung's, checked on the owner's phone 2026-11-24) tell
/// the app their height only after they have finished sliding up. Until
/// then, a button pinned above the keyboard (Create group, Join, a sheet's
/// Save) sits behind it, then jumps up about 0.3 s later.
///
/// So when focus lands on a text field while no keyboard is showing, this
/// reports the keyboard's last known height straight away, through the
/// same [MediaQueryData.viewInsets] every Scaffold and sheet already uses.
/// The real height replaces it as soon as the keyboard reports it. If no
/// keyboard comes (e.g. a hardware keyboard), the space goes after [wait].
///
/// The first keyboard after the app starts has no known height yet, so it
/// still behaves the old way; every one after that is smooth.
class KeyboardSpace extends StatefulWidget {
  const KeyboardSpace({super.key, required this.child});

  final Widget child;

  /// How long to keep the space if the keyboard never reports.
  static const wait = Duration(milliseconds: 600);

  /// The last height the keyboard reported, in logical pixels.
  @visibleForTesting
  static double lastHeight = 0;

  @override
  State<KeyboardSpace> createState() => _KeyboardSpaceState();
}

class _KeyboardSpaceState extends State<KeyboardSpace> {
  bool _opening = false;
  bool _keyboardUp = false;
  double _peak = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_focusChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_focusChanged);
    _timer?.cancel();
    super.dispose();
  }

  void _focusChanged() {
    final context = FocusManager.instance.primaryFocus?.context;
    final onTextField =
        context != null &&
        context.findAncestorStateOfType<EditableTextState>() != null;
    final opening = onTextField && !_keyboardUp && KeyboardSpace.lastHeight > 0;
    _timer?.cancel();
    if (opening) {
      _timer = Timer(KeyboardSpace.wait, () {
        if (mounted) setState(() => _opening = false);
      });
    }
    if (opening != _opening && mounted) setState(() => _opening = opening);
  }

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    final real = data.viewInsets.bottom;
    final wasUp = _keyboardUp;
    _keyboardUp = real > 0;
    if (_keyboardUp) {
      // Remember the tallest height of this keyboard: while it opens or
      // closes it may report in-between heights.
      _peak = real > _peak ? real : _peak;
    } else if (wasUp && _peak > 0) {
      KeyboardSpace.lastHeight = _peak;
      _peak = 0;
    }
    if (_opening && real >= KeyboardSpace.lastHeight) {
      // The keyboard is fully up: its own height takes over.
      _opening = false;
      _timer?.cancel();
    }
    if (!_opening) return widget.child;

    // Never less room than the keyboard already asks for.
    final height = real > KeyboardSpace.lastHeight
        ? real
        : KeyboardSpace.lastHeight;
    return MediaQuery(
      data: data.copyWith(
        viewInsets: data.viewInsets.copyWith(bottom: height),
        // As Android does with a real keyboard: the keyboard covers the
        // navigation bar, so that padding goes.
        padding: data.padding.copyWith(
          bottom: (data.viewPadding.bottom - height).clamp(0, double.infinity),
        ),
      ),
      child: widget.child,
    );
  }
}
