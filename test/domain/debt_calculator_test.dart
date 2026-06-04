import 'package:flutter_test/flutter_test.dart';
import 'package:qadaa/domain/models/prayer_entry.dart';
import 'package:qadaa/domain/models/prayer_type.dart';
import 'package:qadaa/domain/services/debt_calculator.dart';

void main() {
  group('DebtCalculator', () {
    const installDate = '2026-01-01';
    const today = '2026-01-12'; // 11 days after install

    PrayerEntry entry(String date, int count, {bool isJumuah = false}) =>
        PrayerEntry(
          date: date,
          prayerType: PrayerType.fajr,
          count: count,
          isJumuah: isJumuah,
        );

    test('no missed days, no makeups (install today)', () {
      // install_date = today → no days strictly between, so no missed days added
      expect(
        DebtCalculator.calculateDebt(
          initialDebt: 500,
          allEntries: [],
          installDate: today,
          today: today,
        ),
        500,
      );
    });

    test('10 missed past days adds to debt', () {
      // installDate=Jan1, today=Jan12 → Jan2..Jan11 = 10 days, all absent
      expect(
        DebtCalculator.calculateDebt(
          initialDebt: 500,
          allEntries: [],
          installDate: installDate,
          today: today,
        ),
        510,
      );
    });

    test('5 missed days, 5 makeups from prayed days cancel out', () {
      // Jan2-Jan6: count=2 (prayed + 1 makeup each) → NOT missed, 5 makeups
      // Jan7-Jan11: absent → 5 missed days
      // debt = 500 + 5_missed - 5_makeups = 500
      final entries = ['2026-01-02', '2026-01-03', '2026-01-04', '2026-01-05', '2026-01-06']
          .map((d) => entry(d, 2))
          .toList();
      expect(
        DebtCalculator.calculateDebt(
          initialDebt: 500,
          allEntries: entries,
          installDate: installDate,
          today: today,
        ),
        500,
      );
    });

    test('today is excluded from missed days', () {
      // today has no entry — should not count as missed
      expect(
        DebtCalculator.calculateDebt(
          initialDebt: 0,
          allEntries: [],
          installDate: today, // install today
          today: today,
        ),
        0, // no days strictly between installDate and today
      );
    });

    test('is_jumuah=1 row not counted as missed', () {
      final jumuahEntry = PrayerEntry(
        date: '2026-01-02',
        prayerType: PrayerType.dhuhr,
        count: 1,
        isJumuah: true,
      );
      // Dhuhr on Jan2 attended via Jumu'ah → not missed
      final dhuhrEntries = [jumuahEntry];
      // Other 9 days (Jan3-Jan11) still missed
      final debt = DebtCalculator.calculateDebt(
        initialDebt: 0,
        allEntries: dhuhrEntries,
        installDate: installDate,
        today: today,
      );
      expect(debt, 9);
    });

    test('count=0 row same as absent row', () {
      final zeroEntry = entry('2026-01-02', 0);
      final debtWithZero = DebtCalculator.calculateDebt(
        initialDebt: 0,
        allEntries: [zeroEntry],
        installDate: installDate,
        today: today,
      );
      final debtWithout = DebtCalculator.calculateDebt(
        initialDebt: 0,
        allEntries: [],
        installDate: installDate,
        today: today,
      );
      expect(debtWithZero, debtWithout);
    });

    test('avg_per_day=0 returns null (no division by zero)', () {
      final result = DebtCalculator.projectedDailyMakeups(
        allEntries: [],
        today: today,
      );
      expect(result, isNull);
    });

    test('projected daily makeups 7-day average', () {
      // 7 entries each with count=3 → 2 makeups each
      final entries = List.generate(
        7,
        (i) {
          final d = DateTime.parse(today)
              .subtract(Duration(days: i));
          final ds =
              '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          return PrayerEntry(
              date: ds,
              prayerType: PrayerType.fajr,
              count: 3);
        },
      );
      final avg = DebtCalculator.projectedDailyMakeups(
        allEntries: entries,
        today: today,
      );
      expect(avg, closeTo(2.0, 0.01));
    });
  });
}
