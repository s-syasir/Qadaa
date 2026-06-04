import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'app.dart';
import 'data/prayer_repository.dart';
import 'data/settings_repository.dart';
import 'domain/models/prayer_type.dart';
import 'domain/services/debt_calculator.dart';
import 'domain/services/streak_calculator.dart';
import 'notifications/streak_notifier.dart';

/// Background callback invoked when a widget prayer button is tapped
/// while the main app is NOT running.
@pragma('vm:entry-point')
Future<void> widgetBackgroundCallback(Uri? uri) async {
  if (uri == null || uri.host != 'tap') return;
  final prayer = uri.queryParameters['prayer'];
  if (prayer == null) return;

  WidgetsFlutterBinding.ensureInitialized();

  PrayerType prayerType;
  try {
    prayerType = PrayerType.fromString(prayer);
  } catch (_) {
    return;
  }

  final today = _todayString();
  final repo = PrayerRepository();
  await repo.incrementCount(today, prayerType);
  await _refreshWidgetData(repo);
}

Future<void> _refreshWidgetData(PrayerRepository repo) async {
  final today = _todayString();
  final settings = SettingsRepository();
  final allEntries = await repo.getAllEntries();
  final todayEntries = await repo.getEntriesForDate(today);
  final installDate = await settings.get('install_date') ?? today;
  final initialDebts = await settings.getInitialDebts();

  int totalDebt = 0;
  for (final type in PrayerType.values) {
    final typeEntries = allEntries.where((e) => e.prayerType == type).toList();
    totalDebt += DebtCalculator.calculateDebt(
      initialDebt: initialDebts[type] ?? 0,
      allEntries: typeEntries,
      installDate: installDate,
      today: today,
    );
  }

  final streak = StreakCalculator.calculate(allEntries: allEntries, today: today);

  final doneMap = {for (final t in PrayerType.values) t: false};
  for (final e in todayEntries) {
    doneMap[e.prayerType] = e.count >= 1 || e.isJumuah;
  }

  await HomeWidget.saveWidgetData<int>('streak', streak);
  await HomeWidget.saveWidgetData<int>('total_debt', totalDebt);
  await HomeWidget.saveWidgetData<bool>('fajr_done', doneMap[PrayerType.fajr] ?? false);
  await HomeWidget.saveWidgetData<bool>('dhuhr_done', doneMap[PrayerType.dhuhr] ?? false);
  await HomeWidget.saveWidgetData<bool>('asr_done', doneMap[PrayerType.asr] ?? false);
  await HomeWidget.saveWidgetData<bool>(
      'maghrib_done', doneMap[PrayerType.maghrib] ?? false);
  await HomeWidget.saveWidgetData<bool>('isha_done', doneMap[PrayerType.isha] ?? false);
  await HomeWidget.updateWidget(androidName: 'QadaaWidgetProvider');
}

String _todayString() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HomeWidget.registerInteractivityCallback(widgetBackgroundCallback);
  await StreakNotifier.instance.init();
  runApp(const ProviderScope(child: QadaaApp()));
}
