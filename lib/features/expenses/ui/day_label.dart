import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';

/// "Today", "Yesterday", "12 Nov", or "12 Nov 2025" for another year
/// (DESIGN.md §6 date headers).
String dayLabel(AppLocalizations l10n, DateTime day, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final d = _dateOnly(day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return l10n.dateToday;
  if (diff == 1) return l10n.dateYesterday;
  final pattern = d.year == today.year ? 'd MMM' : 'd MMM y';
  return DateFormat(pattern, l10n.localeName).format(d);
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
