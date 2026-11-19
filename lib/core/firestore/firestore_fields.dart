import 'package:cloud_firestore/cloud_firestore.dart';

/// Collection names, in one place (PLAN.md §7).
abstract final class Col {
  static const users = 'users';
  static const groups = 'groups';
  static const members = 'members';
  static const expenses = 'expenses';
  static const settlements = 'settlements';
  static const activity = 'activity';
  static const joinCodes = 'joinCodes';
  static const joins = 'joins';
}

typedef Json = Map<String, Object?>;

/// A server timestamp reads as null until the write reaches the server
/// (e.g. offline), so fall back to "now" for display.
DateTime readDate(Object? value) =>
    value is Timestamp ? value.toDate() : DateTime.now();

DateTime? readOptionalDate(Object? value) =>
    value is Timestamp ? value.toDate() : null;

String readString(Object? value) => value is String ? value : '';

bool readBool(Object? value, {bool fallback = false}) =>
    value is bool ? value : fallback;

/// memberId → paisa. Returns null if the field is missing or any value isn't
/// an int, so bad stored data is caught instead of read as money.
Map<String, int>? readPaisaMap(Object? value) {
  if (value is! Map) return null;
  final out = <String, int>{};
  for (final entry in value.entries) {
    final key = entry.key, paisa = entry.value;
    if (key is! String || paisa is! int) return null;
    out[key] = paisa;
  }
  return out;
}

Json? readJson(Object? value) =>
    value is Map ? Map<String, Object?>.from(value) : null;

List<String> readStringList(Object? value) => [
  for (final item in (value as List?) ?? const [])
    if (item is String) item,
];

/// Null for unknown values (e.g. a newer app version wrote a new type).
T? readEnum<T extends Enum>(List<T> values, Object? value) =>
    value is String ? values.asNameMap()[value] : null;

/// How long to wait for the server before treating a write as queued.
const _queueAfter = Duration(seconds: 4);

/// Commits [batch]. Offline, Firestore applies it to the local cache at once
/// and syncs later, but the Future only completes when the server answers.
/// So wait briefly: server errors in that window are thrown; after it the
/// write is treated as queued and the UI moves on (PLAN.md §3 offline use).
Future<void> commitOrQueue(WriteBatch batch) =>
    batch.commit().timeout(_queueAfter, onTimeout: () {});
