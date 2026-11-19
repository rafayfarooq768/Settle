import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_sizes.dart';
import '../theme/app_theme_extensions.dart';

/// Initials on a flat brand colour (DESIGN.md §6). People are circles; groups are
/// rounded squares ([MemberAvatar.group]). Placeholders get an outline
/// instead of a fill. No photos.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.name,
    this.placeholder = false,
    this.size = AppSizes.avatar,
    this.ring,
  }) : isGroup = false;

  const MemberAvatar.group({super.key, required this.name})
    : placeholder = false,
      size = AppSizes.avatar,
      ring = null,
      isGroup = true;

  final String name;
  final bool placeholder;
  final double size;
  final bool isGroup;

  /// Colour of a thin ring that separates overlapping avatars.
  final Color? ring;

  static String initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.take(2).map((w) => w.characters.first.toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.extraColors;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fill = isGroup ? colors.groupTile : colors.avatar;
    final onFill = isGroup ? colors.onGroupTile : colors.onAvatar;
    final small = size < AppSizes.avatar;
    final textStyle =
        (small ? theme.textTheme.labelSmall : theme.textTheme.labelLarge)
            ?.copyWith(color: placeholder ? scheme.onSurfaceVariant : onFill);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: isGroup ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isGroup
            ? BorderRadius.circular(AppRadius.standard)
            : null,
        color: placeholder ? colors.panel : fill,
        border: placeholder
            ? Border.all(color: scheme.outline, width: AppSizes.avatarOutline)
            : ring == null
            ? null
            : Border.all(color: ring!, width: AppSizes.avatarOutline * 2),
      ),
      child: Text(initials(name), style: textStyle),
    );
  }
}

/// Up to [max] small overlapping avatars, then "+N" (DESIGN.md §6).
class AvatarRow extends StatelessWidget {
  const AvatarRow({super.key, required this.names, this.max = 5});

  final List<({String name, bool placeholder})> names;
  final int max;

  @override
  Widget build(BuildContext context) {
    final shown = names.take(max).toList();
    final extra = names.length - shown.length;
    final step = AppSizes.avatarSmall - AppSizes.avatarOverlap;
    final ring = context.extraColors.panel;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: shown.isEmpty
              ? 0
              : step * (shown.length - 1) + AppSizes.avatarSmall,
          height: AppSizes.avatarSmall,
          child: Stack(
            children: [
              for (var i = 0; i < shown.length; i++)
                PositionedDirectional(
                  start: step * i,
                  child: MemberAvatar(
                    name: shown[i].name,
                    placeholder: shown[i].placeholder,
                    size: AppSizes.avatarSmall,
                    ring: ring,
                  ),
                ),
            ],
          ),
        ),
        if (extra > 0)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
            child: Text(
              '+$extra',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
