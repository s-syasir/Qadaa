import 'package:sqflite/sqflite.dart';
import '../domain/models/prayer_type.dart';
import 'database.dart';

class SettingsRepository {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<String?> get(String key) async {
    final db = await _db;
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> set(String key, String value) async {
    final db = await _db;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String key) async {
    final db = await _db;
    await db.delete('app_settings', where: 'key = ?', whereArgs: [key]);
  }

  Future<Map<PrayerType, int>> getInitialDebts() async {
    final db = await _db;
    final rows = await db.query('initial_debt');
    final result = <PrayerType, int>{};
    for (final row in rows) {
      try {
        final type = PrayerType.fromString(row['prayer_type'] as String);
        result[type] = row['count'] as int;
      } catch (_) {}
    }
    // Defaults to 0 for any missing type
    for (final type in PrayerType.values) {
      result.putIfAbsent(type, () => 0);
    }
    return result;
  }

  Future<void> setInitialDebt(PrayerType type, int count) async {
    final db = await _db;
    await db.insert(
      'initial_debt',
      {'prayer_type': type.name, 'count': count},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setAllInitialDebts(Map<PrayerType, int> debts) async {
    final db = await _db;
    final batch = db.batch();
    for (final entry in debts.entries) {
      batch.insert(
        'initial_debt',
        {'prayer_type': entry.key.name, 'count': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<int> getBestStreak() async {
    final val = await get('best_streak');
    return int.tryParse(val ?? '0') ?? 0;
  }

  Future<void> setBestStreak(int streak) async {
    await set('best_streak', streak.toString());
  }
}
