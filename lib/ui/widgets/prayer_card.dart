import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/prayer_entry.dart';
import '../../domain/models/prayer_type.dart';
import '../../providers.dart';

class PrayerCard extends ConsumerWidget {
  final PrayerType type;
  final PrayerEntry? entry;
  final String today;
  final bool isFriday;
  final DateTime? prayerTime;

  const PrayerCard({
    super.key,
    required this.type,
    required this.entry,
    required this.today,
    required this.isFriday,
    this.prayerTime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = entry?.count ?? 0;
    final prayed = count >= 1 || (entry?.isJumuah ?? false);
    final isJumuah = entry?.isJumuah ?? false;
    final atMax = count >= 100;

    final cardColor = prayed
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    final timeLabel = prayerTime != null
        ? DateFormat('h:mm a').format(prayerTime!)
        : null;

    return Dismissible(
      key: ValueKey('${type.name}_$today'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _decrement(ref);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade100,
        child: const Icon(Icons.remove_circle_outline, color: Colors.red),
      ),
      child: Card(
        color: cardColor,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Prayer name + time
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.arabicName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      type.displayName,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary),
                    ),
                    if (timeLabel != null)
                      Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              // Count / status badge
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    if (prayed) ...[
                      const Icon(Icons.check_circle, color: Colors.green),
                      if (count > 1)
                        Text(
                          '+${count - 1} makeup${count > 2 ? 's' : ''}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.green),
                        ),
                      if (isJumuah)
                        const Text('Jumu\'ah',
                            style:
                                TextStyle(fontSize: 11, color: Colors.teal)),
                    ] else
                      Text(
                        'Not prayed',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12),
                      ),
                  ],
                ),
              ),
              // Controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: count > 0 ? () => _decrement(ref) : null,
                    iconSize: 20,
                  ),
                  ElevatedButton(
                    onPressed: atMax ? null : () => _increment(ref),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('TAP'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _increment(WidgetRef ref) async {
    await ref.read(prayerRepoProvider).incrementCount(today, type);
    ref.invalidate(todayEntriesProvider);
    ref.invalidate(debtSummaryProvider);
  }

  Future<void> _decrement(WidgetRef ref) async {
    await ref.read(prayerRepoProvider).decrementCount(today, type);
    ref.invalidate(todayEntriesProvider);
    ref.invalidate(debtSummaryProvider);
  }
}
