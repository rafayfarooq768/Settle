/// What happened. The UI turns this into localized text, so nothing
/// user-facing is stored in English (CLAUDE.md: strings live in ARB files).
enum ActivityType {
  groupCreated,
  groupRenamed,
  joinCodeRegenerated,
  placeholderAdded,
  memberRenamed,
  memberJoined,
  placeholderClaimed,
  memberLeft,
  expenseAdded,
  expenseEdited,
  expenseDeleted,
  expenseRestored,
  settlementRecorded,
  settlementConfirmed,
  settlementDeleted,
}

/// `groups/{groupId}/activity/{activityId}` (PLAN.md §7). Append-only:
/// security rules forbid editing or deleting entries.
class Activity {
  const Activity({
    required this.id,
    required this.type,
    required this.actorMemberId,
    required this.createdAt,
    this.targetId,
    this.summary = '',
    this.before,
    this.after,
  });

  final String id;
  final ActivityType type;
  final String actorMemberId;
  final DateTime createdAt;

  /// The expense, settlement or member this is about.
  final String? targetId;

  /// Data, not UI copy: the expense title or member name at the time.
  final String summary;

  /// Field snapshots for edits and deletes, so history can show changes.
  final Map<String, Object?>? before;
  final Map<String, Object?>? after;
}
