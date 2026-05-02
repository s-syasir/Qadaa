import 'prayer_type.dart';

class DebtSummary {
  final Map<PrayerType, int> debtByType;
  final int streak;
  final int bestStreak;
  final Map<PrayerType, double?> projectedDaysToPayoff;

  const DebtSummary({
    required this.debtByType,
    required this.streak,
    required this.bestStreak,
    required this.projectedDaysToPayoff,
  });

  int get totalDebt => debtByType.values.fold(0, (a, b) => a + b);
}
