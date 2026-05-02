import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart';

class _City {
  final String name;
  final double lat;
  final double lng;

  const _City({required this.name, required this.lat, required this.lng});
}

class CityScreen extends ConsumerStatefulWidget {
  const CityScreen({super.key});

  @override
  ConsumerState<CityScreen> createState() => _CityScreenState();
}

class _CityScreenState extends ConsumerState<CityScreen> {
  List<_City> _allCities = [];
  List<_City> _results = [];
  final _searchCtrl = TextEditingController();
  _City? _selected;
  bool _loading = true;
  bool _manual = false;
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _cityNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    final raw = await rootBundle.loadString('assets/cities.json');
    final list = json.decode(raw) as List<dynamic>;
    setState(() {
      _allCities = list
          .map((c) => _City(
                name: '${c['name']}, ${c['country']}',
                lat: (c['lat'] as num).toDouble(),
                lng: (c['lng'] as num).toDouble(),
              ))
          .toList();
      _loading = false;
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
          .where((c) => c.name.toLowerCase().contains(lower))
          .take(20)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup — Step 3 of 4')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Where are you based?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('For prayer times.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            if (!_manual) ...[
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search city...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _search,
              ),
              if (_loading) const LinearProgressIndicator(),
              if (_results.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final city = _results[i];
                      return ListTile(
                        title: Text(city.name),
                        selected: _selected == city,
                        onTap: () =>
                            setState(() => _selected = city),
                      );
                    },
                  ),
                ),
              if (_searchCtrl.text.isNotEmpty && _results.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('City not found.'),
                    TextButton(
                      onPressed: () => setState(() => _manual = true),
                      child:
                          const Text('Enter coordinates manually'),
                    ),
                  ],
                ),
              if (_selected != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Selected: ${_selected!.name} (${_selected!.lat.toStringAsFixed(4)}, ${_selected!.lng.toStringAsFixed(4)})',
                    style: const TextStyle(color: Colors.teal),
                  ),
                ),
            ] else ...[
              TextField(
                controller: _cityNameCtrl,
                decoration: const InputDecoration(
                    labelText: 'City name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _latCtrl,
                decoration: const InputDecoration(
                    labelText: 'Latitude', border: OutlineInputBorder()),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _lngCtrl,
                decoration: const InputDecoration(
                    labelText: 'Longitude', border: OutlineInputBorder()),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canProceed() ? _proceed : null,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Set City', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    if (_manual) {
      return _cityNameCtrl.text.isNotEmpty &&
          double.tryParse(_latCtrl.text) != null &&
          double.tryParse(_lngCtrl.text) != null;
    }
    return _selected != null;
  }

  Future<void> _proceed() async {
    final repo = ref.read(settingsRepoProvider);
    if (_manual) {
      await repo.set('city_name', _cityNameCtrl.text);
      await repo.set('city_lat', _latCtrl.text);
      await repo.set('city_lng', _lngCtrl.text);
    } else {
      await repo.set('city_name', _selected!.name);
      await repo.set('city_lat', _selected!.lat.toString());
      await repo.set('city_lng', _selected!.lng.toString());
    }
    if (!mounted) return;
    Navigator.pushNamed(context, '/setup/method');
  }
}
