import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/core/theme/app_colors.dart';
import 'package:settle/core/theme/app_theme.dart';

void main() {
  // Bug (2026-11-20): chip names were unreadable, the label colour was
  // given as a WidgetStateTextStyle, which chips ignore.
  for (final (name, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    testWidgets('chip names are readable ($name)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Column(
              children: [
                FilterChip(
                  label: const Text('On'),
                  selected: true,
                  onSelected: (_) {},
                ),
                FilterChip(
                  label: const Text('Off'),
                  selected: false,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Color colorOf(String t) =>
          tester.renderObject<RenderParagraph>(find.text(t)).text.style!.color!;
      expect(colorOf('On'), AppColors.white);
      expect(colorOf('Off'), theme.colorScheme.onSurface);
    });
  }
}
