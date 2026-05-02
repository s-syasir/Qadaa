import '../models/prayer_entry.dart';
import '../models/prayer_type.dart';

class StreakCalculator {
  /// Returns current streak (consecutive days ending with today or yesterday
  /// where all 5 prayers count >= 1 or is_jumuah = 1 for Dhuhr on Fridays).
  static int calculate({
    required List<PrayerEntry> allEntries,
    required String today,
  }) {
    final byDate = <String, Map<PrayerType, PrayerEntry>>{};
    for (final e in allEntries) {
      byDate.putIfAbsent(e.date, () => {})[e.prayerType] = e;
    }

    bool dayComplete(String date) {
      final entries = byDate[date];
      if (entries == null) return false;
      for (final type in PrayerType.values) {
        final e = entries[type];
        if (e == null) return false;
        if (e.count < 1 && !e.isJumuah) return false;
      }
      return true;
    }

    // Start checking from today; if today incomplete, start from yesterday
    var cursor = today;
    if (!dayComplete(cursor)) {
      cursor = _prevDay(cursor);
    }

    int streak = 0;
    while (dayComplete(cursor)) {
      streak++;
      cursor = _prevDay(cursor);
    }
    return streak;
  }

  static String _prevDay(String date) {
    final d = DateTime.parse(date).subtract(const Duration(days: 1));
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
