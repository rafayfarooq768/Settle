import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/error_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/section_label.dart';
import '../../../core/widgets/tab_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../expenses/ui/day_label.dart';
import '../../groups/domain/group.dart';
import '../../groups/ui/groups_providers.dart';
import '../domain/activity.dart';
import 'activity_providers.dart';
import 'activity_text.dart';

/// Every add, edit, delete and payment in a group, with who did it
/// (PLAN.md §3 item 12), newest first under day labels like the expense
/// list. Entries about an expense open it.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final entries = ref.watch(activityProvider(groupId));
    final members = ref.watch(membersProvider(groupId)).valueOrNull ?? [];
    final me = ref.watch(myMemberProvider(groupId)).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.activityTitle)),
      body: SafeArea(
        child: entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => TabMessage(errorText(l10n, e)),
          data: (list) => list.isEmpty
              ? TabMessage(l10n.activityEmpty)
              : _ActivityList(
                  groupId: groupId,
                  entries: list,
                  members: members,
                  meId: me?.id ?? '',
                ),
        ),
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({
    required this.groupId,
    required this.entries,
    required this.members,
    required this.meId,
  });

  final String groupId;
  final List<Activity> entries;
  final List<Member> members;
  final String meId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final byDay = <DateTime, List<Activity>>{};
    for (final a in entries) {
      final d = a.createdAt;
      byDay.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(a);
    }
    final days = byDay.entries.toList();
    // One item per day, built only as it scrolls into view.
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      itemCount: days.length,
      itemBuilder: (context, i) {
        final MapEntry(key: day, value: list) = days[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionLabel(dayLabel(l10n, day)),
            Panel(
              dividerIndent: avatarRowDividerIndent,
              children: [
                for (final a in list)
                  ActivityRow(
                    activity: a,
                    members: members,
                    meId: meId,
                    onTap: isExpenseActivity(a.type) && a.targetId != null
                        ? () => context.push(
                            '/groups/$groupId/expenses/${a.targetId}',
                          )
                        : null,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Who did it (avatar), the sentence, an optional muted detail, and the
/// time at the end. Also used for an expense's History.
class ActivityRow extends StatelessWidget {
  const ActivityRow({
    super.key,
    required this.activity,
    required this.members,
    required this.meId,
    this.onTap,
  });

  final Activity activity;
  final List<Member> members;
  final String meId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final actor = members
        .where((m) => m.id == activity.actorMemberId)
        .firstOrNull;
    final (:text, :detail) = activityText(
      l10n,
      activity,
      names: {for (final m in members) m.id: m.displayName},
      meId: meId,
    );
    return ListTile(
      minTileHeight: AppSpacing.rowHeight,
      leading: MemberAvatar(
        name: actor?.displayName ?? '?',
        placeholder: actor?.isPlaceholder ?? false,
      ),
      // A sentence, not a name: regular weight.
      title: Text(
        text,
        style: theme.textTheme.bodyLarge,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: detail == null ? null : Text(detail),
      trailing: Text(
        DateFormat.jm(l10n.localeName).format(activity.createdAt),
        style: theme.textTheme.bodySmall?.copyWith(color: muted),
      ),
      onTap: onTap,
    );
  }
}
