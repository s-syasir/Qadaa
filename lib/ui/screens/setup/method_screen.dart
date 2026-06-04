import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart';

class MethodScreen extends ConsumerStatefulWidget {
  const MethodScreen({super.key});

  @override
  ConsumerState<MethodScreen> createState() => _MethodScreenState();
}

class _MethodScreenState extends ConsumerState<MethodScreen> {
  String _method = 'MuslimWorldLeague';
  String _madhab = 'Shafi';
  String _highLatRule = 'angleBased';
  bool _showHighLat = false;

  static const _methods = [
    ('MuslimWorldLeague', 'Muslim World League'),
    ('NorthAmerica', 'ISNA (North America)'),
    ('Egyptian', 'Egyptian General Authority'),
    ('UmmAlQura', 'Umm Al-Qura (Makkah)'),
    ('Karachi', 'University of Islamic Sciences, Karachi'),
    ('Gulf', 'Gulf Region'),
    ('Dubai', 'Dubai'),
    ('MoonsightingCommittee', 'Moonsighting Committee'),
    ('Kuwait', 'Kuwait'),
    ('Qatar', 'Qatar'),
    ('Singapore', 'Singapore'),
    ('Turkey', 'Turkey'),
    ('Tehran', 'Tehran'),
  ];

  static const _highLatRules = [
    ('angleBased', 'Angle Based (default)'),
    ('middleOfNight', 'Middle of Night'),
    ('seventhOfNight', 'Seventh of Night'),
    ('twilightAngle', 'Twilight Angle'),
  ];

  @override
  void initState() {
    super.initState();
    _checkLatitude();
  }

  Future<void> _checkLatitude() async {
    final repo = ref.read(settingsRepoProvider);
    final latStr = await repo.get('city_lat');
    if (latStr != null) {
      final lat = double.tryParse(latStr) ?? 0;
      setState(() => _showHighLat = lat.abs() > 48);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup — Step 4 of 4')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prayer time calculation',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Which method does your local mosque follow?',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  // Method dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _method,
                    decoration: const InputDecoration(
                      labelText: 'Calculation Method',
                      border: OutlineInputBorder(),
                    ),
                    items: _methods
                        .map((m) => DropdownMenuItem(
                              value: m.$1,
                              child: Text(m.$2),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _method = v!),
                  ),
                  const SizedBox(height: 16),
                  // Madhab
                  const Text('Asr calculation (Madhab)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  RadioGroup<String>(
                    groupValue: _madhab,
                    onChanged: (v) => setState(() => _madhab = v!),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Shafi\'i / Maliki / Hanbali'),
                          value: 'Shafi',
                        ),
                        RadioListTile<String>(
                          title: const Text('Hanafi'),
                          value: 'Hanafi',
                        ),
                      ],
                    ),
                  ),
                  // High latitude rule (only if lat > 48)
                  if (_showHighLat) ...[
                    const SizedBox(height: 16),
                    const Text('High Latitude Rule',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    RadioGroup<String>(
                      groupValue: _highLatRule,
                      onChanged: (v) => setState(() => _highLatRule = v!),
                      child: Column(
                        children: _highLatRules
                            .map((r) => RadioListTile<String>(
                                  title: Text(r.$2),
                                  value: r.$1,
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _finish,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Done — Start Tracking',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finish() async {
    final repo = ref.read(settingsRepoProvider);
    await repo.set('calculation_method', _method);
    await repo.set('madhab', _madhab);
    await repo.set('high_latitude_rule', _highLatRule);
    final today = ref.read(todayProvider);
    await repo.set('install_date', today);
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }
}
