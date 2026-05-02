import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/prayer_type.dart';
import '../../providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtSummary = ref.watch(debtSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: debtSummary.when(
        data: (summary) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Debt table
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prayer Debt',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1.5),
                        2: FlexColumnWidth(2),
                      },
                      children: [
                        const TableRow(
                          decoration:
                              BoxDecoration(border: Border(bottom: BorderSide())),
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text('Prayer',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                            Text('Debt',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text('Payoff (est.)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        ...PrayerType.values.map((type) {
                          final debt = summary.debtByType[type] ?? 0;
                          final days = summary.projectedDaysToPayoff[type];
                          return TableRow(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Text(type.displayName),
                              ),
                              Text(NumberFormat('#,###').format(debt)),
                              Text(_formatPayoff(days)),
                            ],
                          );
                        }),
                        TableRow(
                          decoration: const BoxDecoration(
                              border: Border(top: BorderSide())),
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('Total',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                            Text(
                              NumberFormat('#,###').format(summary.totalDebt),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            const Text(''),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Streak card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Streak',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('🔥 Current streak: ',
                            style: TextStyle(fontSize: 16)),
                        Text(
                          '${summary.streak} day${summary.streak == 1 ? '' : 's'}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('Best streak: ',
                            style: TextStyle(fontSize: 14)),
                        Text(
                          '${summary.bestStreak} day${summary.bestStreak == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _formatPayoff(double? days) {
    if (days == null) return 'No makeups in 7d';
    if (days < 30) return '${days.round()} days';
    if (days < 365) return '${(days / 30).toStringAsFixed(1)} months';
    return '${(days / 365).toStringAsFixed(1)} years';
  }
}
