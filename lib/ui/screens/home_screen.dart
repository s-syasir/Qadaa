import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/prayer_type.dart';
import '../../providers.dart';
import '../widgets/prayer_card.dart';
import 'stats_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final todayEntries = ref.watch(todayEntriesProvider);
    final debtSummary = ref.watch(debtSummaryProvider);
    final prayerTimes = ref.watch(prayerTimesProvider);
    ref.watch(streakNotificationProvider); // side-effect: reschedules streak alert
    ref.watch(widgetSyncProvider); // side-effect: syncs home screen widget

    final now = DateTime.now();
    final isFriday = now.weekday == DateTime.friday;
    final dateLabel = DateFormat('EEEE, d MMMM yyyy').format(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qadaa'),
        actions: [
          debtSummary.when(
            data: (summary) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const StatsScreen())),
                icon: Text(
                  '🔥 ${summary.streak}',
                  style: const TextStyle(fontSize: 16),
                ),
                label: const Text('Stats'),
              ),
            ),
            loading: () => const SizedBox(),
            error: (e, s) => const SizedBox(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(dateLabel,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                debtSummary.when(
                  data: (summary) => Text(
                    'Total debt: ${NumberFormat('#,###').format(summary.totalDebt)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: summary.totalDebt > 0
                              ? Theme.of(context).colorScheme.error
                              : Colors.green,
                        ),
                  ),
                  loading: () =>
                      const CircularProgressIndicator(strokeWidth: 2),
                  error: (e, _) => Text('Error: $e'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Prayer cards
          Expanded(
            child: todayEntries.when(
              data: (entries) {
                final times = prayerTimes.valueOrNull;
                return ListView(
                children: [
                  ...PrayerType.values.map((type) {
                    final widgets = <Widget>[
                      PrayerCard(
                        type: type,
                        entry: entries[type],
                        today: today,
                        isFriday: isFriday,
                        prayerTime: times?[type],
                      ),
                    ];
                    // Jumu'ah banner after Dhuhr card on Fridays
                    if (type == PrayerType.dhuhr && isFriday) {
                      widgets.add(JumuahBanner(
                        today: today,
                        isAttended: entries[PrayerType.dhuhr]?.isJumuah ?? false,
                      ));
                    }
                    return widgets;
                  }).expand((w) => w),
                ],
              );},
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class JumuahBanner extends ConsumerWidget {
  final String today;
  final bool isAttended;

  const JumuahBanner({super.key, required this.today, required this.isAttended});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: isAttended
            ? null
            : () async {
                await ref.read(prayerRepoProvider).setJumuah(today);
                ref.invalidate(todayEntriesProvider);
                ref.invalidate(debtSummaryProvider);
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isAttended
                ? Colors.teal.shade100
                : Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isAttended ? Colors.teal : Colors.teal.shade200),
          ),
          child: Row(
            children: [
              Icon(
                isAttended ? Icons.check_circle : Icons.mosque,
                color: Colors.teal,
              ),
              const SizedBox(width: 12),
              Text(
                isAttended
                    ? 'Jumu\'ah attended ✓'
                    : 'FRIDAY: Jumu\'ah attended?',
                style: TextStyle(
                  color: Colors.teal.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
