import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/prayer_type.dart';
import '../../../providers.dart';

class AdjustDebtScreen extends ConsumerStatefulWidget {
  const AdjustDebtScreen({super.key});

  @override
  ConsumerState<AdjustDebtScreen> createState() => _AdjustDebtScreenState();
}

class _AdjustDebtScreenState extends ConsumerState<AdjustDebtScreen> {
  Map<PrayerType, int>? _debts;
  bool _initialized = false;

  void _init(int birthYear) {
    if (_initialized) return;
    _initialized = true;
    final currentYear = DateTime.now().year;
    final years = currentYear - birthYear - 12;
    final estimate = (years * 365).clamp(0, 999999);
    _debts = {for (final t in PrayerType.values) t: estimate};
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _init(args['birthYear'] as int);
    final debts = _debts!;

    return Scaffold(
      appBar: AppBar(title: const Text('Setup — Step 2 of 4')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adjust your starting debt',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Adjust if you know you prayed some of these regularly.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: PrayerType.values.map((type) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(type.arabicName,
                                  style: const TextStyle(fontSize: 18)),
                              Text(type.displayName,
                                  style:
                                      const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: debts[type]! > 0
                              ? () => setState(
                                  () => debts[type] = debts[type]! - 1)
                              : null,
                        ),
                        SizedBox(
                          width: 70,
                          child: TextFormField(
                            initialValue: '${debts[type]}',
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null && n >= 0) {
                                setState(() => debts[type] = n);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () =>
                              setState(() => debts[type] = debts[type]! + 1),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final settingsRepo = ref.read(settingsRepoProvider);
                  await settingsRepo.setAllInitialDebts(debts);
                  if (context.mounted) {
                    Navigator.pushNamed(context, '/setup/city');
                  }
                },
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Confirm Debt',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
