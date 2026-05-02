import 'package:flutter_test/flutter_test.dart';
import 'package:qadaa/domain/models/prayer_entry.dart';
import 'package:qadaa/domain/models/prayer_type.dart';
import 'package:qadaa/domain/services/streak_calculator.dart';

void main() {
  const today = '2026-01-10';

  List<PrayerEntry> fullDay(String date, {bool jumuahDhuhr = false}) =>
      PrayerType.values.map((t) => PrayerEntry(
            date: date,
            prayerType: t,
            count: 1,
            isJumuah: jumuahDhuhr && t == PrayerType.dhuhr,
          )).toList();

  group('StreakCalculator', () {
    test('no entries → streak 0', () {
      expect(StreakCalculator.calculate(allEntries: [], today: today), 0);
    });

    test('only today complete → streak 1 (counts as in progress)', () {
      expect(
        StreakCalculator.calculate(
            allEntries: fullDay(today), today: today),
        1,
      );
    });

    test('yesterday + today complete → streak 2', () {
      final entries = [...fullDay('2026-01-09'), ...fullDay(today)];
      expect(
        StreakCalculator.calculate(allEntries: entries, today: today),
        2,
      );
    });

    test('gap breaks streak', () {
      // Jan 8 missing, Jan 9 + 10 present
      final entries = [...fullDay('2026-01-07'), ...fullDay('2026-01-09'), ...fullDay(today)];
      expect(
        StreakCalculator.calculate(allEntries: entries, today: today),
        2, // Jan9 + Jan10
      );
    });

    test('jumu\'ah satisfies dhuhr for streak', () {
      final friday = '2026-01-09'; // Assuming it's a Friday in test
      final entries = [...fullDay(friday, jumuahDhuhr: true), ...fullDay(today)];
      expect(
        StreakCalculator.calculate(allEntries: entries, today: today),
        2,
      );
    });

    test('missing one prayer on a day breaks streak for that day', () {
      // Jan 9: only 4 prayers
      final partial = PrayerType.values
          .where((t) => t != PrayerType.fajr)
          .map((t) => PrayerEntry(date: '2026-01-09', prayerType: t, count: 1))
          .toList();
      final entries = [...partial, ...fullDay(today)];
      expect(
        StreakCalculator.calculate(allEntries: entries, today: today),
        1, // only today counts
      );
    });
  });
}
