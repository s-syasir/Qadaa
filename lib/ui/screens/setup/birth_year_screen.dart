import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BirthYearScreen extends ConsumerStatefulWidget {
  const BirthYearScreen({super.key});

  @override
  ConsumerState<BirthYearScreen> createState() => _BirthYearScreenState();
}

class _BirthYearScreenState extends ConsumerState<BirthYearScreen> {
  int _year = DateTime.now().year - 25;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final maxYear = currentYear - 12;
    final estimatedYears = (_year <= maxYear) ? currentYear - _year - 12 : 0;
    final estimatedDebt = estimatedYears * 365;

    return Scaffold(
      appBar: AppBar(title: const Text('Setup — Step 1 of 4')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What year were you born?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Qadaa applies from age 12. We\'ll use this to estimate your starting debt.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  iconSize: 32,
                  onPressed: () => setState(() {
                    _year--;
                    _error = null;
                  }),
                ),
                const SizedBox(width: 24),
                Text(
                  '$_year',
                  style: const TextStyle(
                      fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.add),
                  iconSize: 32,
                  onPressed: () => setState(() {
                    _year++;
                    _error = null;
                  }),
                ),
              ],
            ),
            if (_year <= maxYear) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Assuming 100% missed, your estimated starting debt per prayer is ~$estimatedDebt prayers ($estimatedYears years).',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_year > maxYear) {
                    setState(() => _error =
                        'You must be at least 12 for qadaa to apply.');
                    return;
                  }
                  Navigator.pushNamed(
                    context,
                    '/setup/adjust-debt',
                    arguments: {'birthYear': _year},
                  );
                },
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Next', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
