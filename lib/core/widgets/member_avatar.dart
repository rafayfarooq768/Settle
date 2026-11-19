import 'package:flutter/material.dart';

import '../theme/app_sizes.dart';
import '../theme/app_theme_extensions.dart';

/// Initials on a flat tinted circle (DESIGN.md §6). Placeholders get an
/// outline instead of a fill. No photos.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.name, this.placeholder = false});

  final String name;
  final bool placeholder;

  static String initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final letters = words.take(2).map((w) => w.characters.first.toUpperCase());
    return letters.join();
  }

  /// Stable across launches and phones (String.hashCode isn't).
  static int tintIndex(String name, int count) =>
      name.trim().toLowerCase().codeUnits.fold<int>(0, (a, b) => a + b) % count;

  @override
  Widget build(BuildContext context) {
    final colors = context.extraColors;
    final scheme = Theme.of(context).colorScheme;
    final tint = colors.avatarTints[tintIndex(name, colors.avatarTints.length)];
    return Container(
      width: AppSizes.avatar,
      height: AppSizes.avatar,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: placeholder ? null : tint,
        border: placeholder
            ? Border.all(color: scheme.outline, width: AppSizes.avatarOutline)
            : null,
      ),
      child: Text(
        initials(name),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: placeholder ? scheme.onSurfaceVariant : colors.onAvatar,
        ),
      ),
    );
  }
}
