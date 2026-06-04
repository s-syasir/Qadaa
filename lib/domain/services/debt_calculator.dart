import '../models/prayer_entry.dart';

class DebtCalculator {
  /// Calculates current debt for a single prayer type.
  ///
  /// [initialDebt] — from initial_debt table
  /// [allEntries] — all prayer_entries rows for this type (all time)
  /// [installDate] — "YYYY-MM-DD", counts missed days strictly after this
  /// [today] — "YYYY-MM-DD", excluded from missed days
  static int calculateDebt({
    required int initialDebt,
    required List<PrayerEntry> allEntries,
    required String installDate,
    required String today,
  }) {
    final entryByDate = {for (final e in allEntries) e.date: e};

    // Missed days: dates strictly after installDate and strictly before today
    // where count=0 or row absent (and not is_jumuah)
    int missedDays = 0;
    var cursor = _nextDay(installDate);
    while (cursor.compareTo(today) < 0) {
      final entry = entryByDate[cursor];
      final prayed = entry != null && (entry.count >= 1 || entry.isJumuah);
      if (!prayed) missedDays++;
      cursor = _nextDay(cursor);
    }

    // Total makeups = SUM(max(0, count - 1)) across all entries
    int totalMakeups = 0;
    for (final e in allEntries) {
      if (e.count > 1) totalMakeups += e.count - 1;
    }

    return initialDebt + missedDays - totalMakeups;
  }

  /// 7-day moving average of daily makeups, returns null if no makeups.
  static double? projectedDailyMakeups({
    required List<PrayerEntry> allEntries,
    required String today,
  }) {
    final days = <String>[];
    var cursor = today;
    for (var i = 0; i < 7; i++) {
      days.add(cursor);
      cursor = _prevDay(cursor);
    }
    final entryByDate = {for (final e in allEntries) e.date: e};
    double total = 0;
    for (final d in days) {
      final entry = entryByDate[d];
      if (entry != null && entry.count > 1) {
        total += entry.count - 1;
      }
    }
    if (total == 0) return null;
    return total / 7;
  }

  static String _nextDay(String date) {
    final d = DateTime.parse(date).add(const Duration(days: 1));
    return _fmt(d);
  }

  static String _prevDay(String date) {
    final d = DateTime.parse(date).subtract(const Duration(days: 1));
    return _fmt(d);
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
