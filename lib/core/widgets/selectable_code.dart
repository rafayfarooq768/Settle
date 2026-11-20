import 'package:material_ui/material_ui.dart';

/// Selectable text whose selection clears when you tap anywhere else.
/// Flutter's SelectableText keeps its selection after losing focus.
class SelectableCode extends StatefulWidget {
  const SelectableCode(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  State<SelectableCode> createState() => _SelectableCodeState();
}

class _SelectableCodeState extends State<SelectableCode> {
  final _focus = FocusNode();
  bool _selected = false;

  // Changing the key rebuilds the text fresh, which drops the selection.
  int _generation = 0;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _clear() {
    _focus.unfocus();
    if (_selected) {
      setState(() {
        _selected = false;
        _generation++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: (_) => _clear(),
      child: SelectableText(
        widget.text,
        key: ValueKey(_generation),
        focusNode: _focus,
        textAlign: TextAlign.center,
        style: widget.style,
        onSelectionChanged: (selection, _) =>
            _selected = !selection.isCollapsed,
      ),
    );
  }
}
