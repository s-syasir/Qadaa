import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'data/prayer_repository.dart';
import 'data/settings_repository.dart';
import 'domain/models/debt_summary.dart';
import 'domain/models/prayer_entry.dart';
import 'domain/models/prayer_type.dart';
import 'domain/services/debt_calculator.dart';
import 'domain/services/prayer_time_service.dart';
import 'domain/services/streak_calculator.dart';
import 'notifications/streak_notifier.dart';

final prayerRepoProvider = Provider((_) => PrayerRepository());
final settingsRepoProvider = Provider((_) => SettingsRepository());

// Today's date as ISO string
final todayProvider = Provider<String>((_) {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
});

// Whether setup has been completed
final installDateProvider = FutureProvider<String?>((ref) async {
  final settings = ref.watch(settingsRepoProvider);
  return settings.get('install_date');
});

// Today's entries for all 5 prayers
final todayEntriesProvider =
    FutureProvider.autoDispose<Map<PrayerType, PrayerEntry?>>((ref) async {
  final repo = ref.watch(prayerRepoProvider);
  final today = ref.watch(todayProvider);
  final entries = await repo.getEntriesForDate(today);
  final map = <PrayerType, PrayerEntry?>{for (final t in PrayerType.values) t: null};
  for (final e in entries) {
    map[e.prayerType] = e;
  }
  return map;
});

// Today's prayer times from adhan
final prayerTimesProvider =
    FutureProvider.autoDispose<Map<PrayerType, DateTime>?>((ref) async {
  final settings = ref.watch(settingsRepoProvider);
  final lat = await settings.get('city_lat');
  final lng = await settings.get('city_lng');
  final method = await settings.get('calculation_method');
  final madhab = await settings.get('madhab');
  final highLatRule = await settings.get('high_latitude_rule');
  return PrayerTimeService.calculate(
    cityLat: lat,
    cityLng: lng,
    method: method,
    madhab: madhab,
    highLatRule: highLatRule,
  );
});

// Full debt summary (memoized, re-evaluated on tap or app resume)
final debtSummaryProvider =
    FutureProvider.autoDispose<DebtSummary>((ref) async {
  final prayerRepo = ref.watch(prayerRepoProvider);
  final settingsRepo = ref.watch(settingsRepoProvider);
  final today = ref.watch(todayProvider);

  final installDate = await settingsRepo.get('install_date') ?? today;
  final initialDebts = await settingsRepo.getInitialDebts();
  final allEntries = await prayerRepo.getAllEntries();

  final debtByType = <PrayerType, int>{};
  final projectedDays = <PrayerType, double?>{};

  for (final type in PrayerType.values) {
    final typeEntries = allEntries.where((e) => e.prayerType == type).toList();
    debtByType[type] = DebtCalculator.calculateDebt(
      initialDebt: initialDebts[type] ?? 0,
      allEntries: typeEntries,
      installDate: installDate,
      today: today,
    );
    final avgPerDay = DebtCalculator.projectedDailyMakeups(
      allEntries: typeEntries,
      today: today,
    );
    projectedDays[type] = avgPerDay != null && debtByType[type]! > 0
        ? debtByType[type]! / avgPerDay
        : null;
  }

  final streak = StreakCalculator.calculate(
    allEntries: allEntries,
    today: today,
  );

  final storedBest = await settingsRepo.getBestStreak();
  final bestStreak = streak > storedBest ? streak : storedBest;
  if (streak > storedBest) {
    await settingsRepo.setBestStreak(streak);
  }

  return DebtSummary(
    debtByType: debtByType,
    streak: streak,
    bestStreak: bestStreak,
    projectedDaysToPayoff: projectedDays,
  );
});

/// Reschedules the streak notification whenever debt summary or today's entries
/// change. Called as a side-effect provider — just watch it from the home screen.
final streakNotificationProvider = FutureProvider.autoDispose<void>((ref) async {
  final summary = await ref.watch(debtSummaryProvider.future);
  final entries = await ref.watch(todayEntriesProvider.future);

  final prayedToday = entries.values
      .where((e) => e != null && (e.count >= 1 || e.isJumuah))
      .length;
  final remaining = 5 - prayedToday;

  await StreakNotifier.instance.reschedule(
    streak: summary.streak,
    prayersRemainingToday: remaining,
  );
});

/// Pushes current prayer state and debt to the home screen widget.
/// Called as a side-effect provider — watch it from the home screen.
final widgetSyncProvider = FutureProvider.autoDispose<void>((ref) async {
  final summary = await ref.watch(debtSummaryProvider.future);
  final entries = await ref.watch(todayEntriesProvider.future);

  await HomeWidget.saveWidgetData<int>('streak', summary.streak);
  await HomeWidget.saveWidgetData<int>('total_debt', summary.totalDebt);
  for (final type in PrayerType.values) {
    final e = entries[type];
    final done = e != null && (e.count >= 1 || e.isJumuah);
    await HomeWidget.saveWidgetData<bool>('${type.name}_done', done);
  }
  await HomeWidget.updateWidget(androidName: 'QadaaWidgetProvider');
});
