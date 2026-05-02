import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/export_service.dart';
import '../../domain/models/prayer_type.dart';
import '../../providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Map<PrayerType, TextEditingController>? _debtControllers;
  bool _loaded = false;
  String? _exportFolder;
  final _folderCtrl = TextEditingController();
  bool _exporting = false;
  bool _importing = false;
  bool _hasPermission = false;

  // Prayer time settings
  String? _cityName;
  String _method = 'MuslimWorldLeague';
  String _madhab = 'Shafi';
  String _highLatRule = 'angleBased';
  bool _showHighLat = false;
  bool _savingPrayerSettings = false;

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
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(settingsRepoProvider);
    final debts = await repo.getInitialDebts();
    final folder = await ExportService.instance.getExportFolder();
    final hasPerm = await ExportService.instance.hasStoragePermission();
    final cityName = await repo.get('city_name');
    final method = await repo.get('calculation_method') ?? 'MuslimWorldLeague';
    final madhab = await repo.get('madhab') ?? 'Shafi';
    final highLatRule = await repo.get('high_latitude_rule') ?? 'angleBased';
    final latStr = await repo.get('city_lat');
    final lat = double.tryParse(latStr ?? '') ?? 0;
    setState(() {
      _debtControllers = {
        for (final t in PrayerType.values)
          t: TextEditingController(text: '${debts[t] ?? 0}')
      };
      _exportFolder = folder;
      _folderCtrl.text = folder;
      _hasPermission = hasPerm;
      _cityName = cityName;
      _method = method;
      _madhab = madhab;
      _highLatRule = highLatRule;
      _showHighLat = lat.abs() > 48;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _debtControllers?.values.forEach((c) => c.dispose());
    _folderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Initial Debt ──────────────────────────────────────
                const Text('Initial Debt',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                  'Adjust your starting debt per prayer type.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ...PrayerType.values.map((type) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(type.arabicName,
                                    style: const TextStyle(fontSize: 16)),
                                Text(type.displayName,
                                    style: const TextStyle(
                                        color: Colors.grey)),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: _debtControllers![type],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _saveDebts,
                  child: const Text('Save debt'),
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                // ── Prayer Times ──────────────────────────────────────
                const Text('Prayer Times',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                  'City and calculation settings.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                // Current city
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('City',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            _cityName ?? 'Not set',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _changeCity,
                      child: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Calculation method
                DropdownButtonFormField<String>(
                  initialValue: _method,
                  decoration: const InputDecoration(
                    labelText: 'Calculation Method',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _methods
                      .map((m) => DropdownMenuItem(
                            value: m.$1,
                            child: Text(m.$2,
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _method = v!),
                ),
                const SizedBox(height: 12),
                // Madhab
                const Text('Asr calculation (Madhab)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                RadioGroup<String>(
                  groupValue: _madhab,
                  onChanged: (v) => setState(() => _madhab = v!),
                  child: Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Shafi\'i / Hanbali',
                              style: TextStyle(fontSize: 13)),
                          value: 'Shafi',
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Hanafi',
                              style: TextStyle(fontSize: 13)),
                          value: 'Hanafi',
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
                // High latitude rule
                if (_showHighLat) ...[
                  const Text('High Latitude Rule',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  RadioGroup<String>(
                    groupValue: _highLatRule,
                    onChanged: (v) => setState(() => _highLatRule = v!),
                    child: Column(
                      children: _highLatRules
                          .map((r) => RadioListTile<String>(
                                title: Text(r.$2,
                                    style: const TextStyle(fontSize: 13)),
                                value: r.$1,
                                contentPadding: EdgeInsets.zero,
                              ))
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _savingPrayerSettings ? null : _savePrayerSettings,
                  child: _savingPrayerSettings
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save prayer time settings'),
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                // ── Backup / Export ───────────────────────────────────
                const Text('Backup',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                  'Export qadaa.db to a folder you can sync with Syncthing.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),

                // Permission banner (shown when permission missing)
                if (!_hasPermission)
                  _PermissionBanner(onGranted: () async {
                    final granted = await ExportService.instance
                        .requestStoragePermission();
                    if (!mounted) return;
                    if (granted) {
                      setState(() => _hasPermission = true);
                    } else {
                      // Permanently denied — send to app settings
                      await openAppSettings();
                    }
                  }),

                if (!_hasPermission) const SizedBox(height: 12),

                TextField(
                  controller: _folderCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Export folder',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.folder_outlined, size: 18),
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  onSubmitted: (_) => _saveFolder(),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saveFolder,
                        child: const Text('Save folder'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        icon: _exporting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(Icons.upload, size: 18),
                        label: const Text('Export now'),
                        onPressed:
                            (_exporting || !_hasPermission) ? null : _export,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: _importing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download, size: 18),
                    label: const Text('Import backup'),
                    onPressed: _importing ? null : _import,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _resetFolder,
                  child: const Text('Reset to default folder'),
                ),
              ],
            ),
    );
  }

  Future<void> _saveFolder() async {
    final path = _folderCtrl.text.trim();
    if (path.isEmpty) return;
    await ExportService.instance.setFolder(path);
    setState(() => _exportFolder = path);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Folder saved')));
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    final result = await ExportService.instance.exportNow();
    if (!mounted) return;
    setState(() => _exporting = false);

    switch (result) {
      case ExportResult.success:
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Exported to $_exportFolder')));
      case ExportResult.permissionDenied:
        setState(() => _hasPermission = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Storage permission required')));
      case ExportResult.cancelled:
        break;
      case ExportResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export failed')));
    }
  }

  Future<void> _import() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import backup?'),
        content: const Text(
            'This will replace ALL current data with the selected backup. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Import')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _importing = true);
    final result = await ExportService.instance.importNow();
    if (!mounted) return;
    setState(() => _importing = false);

    switch (result) {
      case ImportResult.success:
        ref.invalidate(installDateProvider);
        ref.invalidate(todayEntriesProvider);
        ref.invalidate(debtSummaryProvider);
        ref.invalidate(prayerTimesProvider);
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Database restored from backup')));
      case ImportResult.cancelled:
        break;
      case ImportResult.invalidFile:
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select a .db file')));
      case ImportResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Import failed')));
    }
  }

  Future<void> _resetFolder() async {
    await ExportService.instance.resetFolder();
    final folder = await ExportService.instance.getExportFolder();
    setState(() {
      _exportFolder = folder;
      _folderCtrl.text = folder;
    });
  }

  Future<void> _changeCity() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CityPickerSheet(),
    );
    if (result == null) return;
    final repo = ref.read(settingsRepoProvider);
    await repo.set('city_name', result['name'] as String);
    await repo.set('city_lat', result['lat'].toString());
    await repo.set('city_lng', result['lng'].toString());
    final lat = (result['lat'] as double).abs();
    ref.invalidate(prayerTimesProvider);
    if (!mounted) return;
    setState(() {
      _cityName = result['name'] as String;
      _showHighLat = lat > 48;
    });
  }

  Future<void> _savePrayerSettings() async {
    setState(() => _savingPrayerSettings = true);
    final repo = ref.read(settingsRepoProvider);
    await repo.set('calculation_method', _method);
    await repo.set('madhab', _madhab);
    await repo.set('high_latitude_rule', _highLatRule);
    ref.invalidate(prayerTimesProvider);
    if (!mounted) return;
    setState(() => _savingPrayerSettings = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Prayer time settings saved')));
  }

  Future<void> _saveDebts() async {
    final repo = ref.read(settingsRepoProvider);
    final debts = <PrayerType, int>{};
    for (final t in PrayerType.values) {
      debts[t] = int.tryParse(_debtControllers![t]!.text) ?? 0;
    }
    await repo.setAllInitialDebts(debts);
    ref.invalidate(debtSummaryProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Saved')));
  }
}

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet();

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  List<dynamic> _allCities = [];
  List<dynamic> _results = [];
  final _searchCtrl = TextEditingController();
  dynamic _selected;
  bool _loading = true;
  bool _manual = false;
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/cities.json').then((raw) {
      setState(() {
        _allCities = json.decode(raw) as List<dynamic>;
        _loading = false;
      });
    });
  }

  void _search(String q) {
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    final lower = q.toLowerCase();
    setState(() {
      _results = _allCities
          .where((c) =>
              (c['name'] as String).toLowerCase().contains(lower))
          .take(15)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (_, scrollController) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change City',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (!_manual) ...[
              TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search city...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: _search,
              ),
              if (_loading) const LinearProgressIndicator(),
              if (_results.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final c = _results[i];
                      final name = '${c['name']}, ${c['country']}';
                      return ListTile(
                        title: Text(name),
                        selected: _selected == c,
                        onTap: () => setState(() => _selected = c),
                      );
                    },
                  ),
                ),
              if (_searchCtrl.text.isNotEmpty && _results.isEmpty)
                TextButton(
                  onPressed: () => setState(() => _manual = true),
                  child: const Text('Enter coordinates manually'),
                ),
            ] else ...[
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'City name',
                    border: OutlineInputBorder(),
                    isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _latCtrl,
                decoration: const InputDecoration(
                    labelText: 'Latitude',
                    border: OutlineInputBorder(),
                    isDense: true),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _lngCtrl,
                decoration: const InputDecoration(
                    labelText: 'Longitude',
                    border: OutlineInputBorder(),
                    isDense: true),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              TextButton(
                onPressed: () => setState(() => _manual = false),
                child: const Text('Back to search'),
              ),
            ],
            if (_selected != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Selected: ${_selected!['name']}, ${_selected!['country']}',
                  style: const TextStyle(color: Colors.teal, fontSize: 13),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canConfirm() ? _confirm : null,
                child: const Text('Set City'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canConfirm() {
    if (_manual) {
      return _nameCtrl.text.isNotEmpty &&
          double.tryParse(_latCtrl.text) != null &&
          double.tryParse(_lngCtrl.text) != null;
    }
    return _selected != null;
  }

  void _confirm() {
    if (_manual) {
      Navigator.pop(context, {
        'name': _nameCtrl.text,
        'lat': double.parse(_latCtrl.text),
        'lng': double.parse(_lngCtrl.text),
      });
    } else {
      Navigator.pop(context, {
        'name': '${_selected!['name']}, ${_selected!['country']}',
        'lat': (_selected!['lat'] as num).toDouble(),
        'lng': (_selected!['lng'] as num).toDouble(),
      });
    }
  }
}

class _PermissionBanner extends StatelessWidget {
  final VoidCallback onGranted;
  const _PermissionBanner({required this.onGranted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
              size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Storage access required to export to Downloads.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onGranted,
            child: const Text('Grant'),
          ),
        ],
      ),
    );
  }
}
