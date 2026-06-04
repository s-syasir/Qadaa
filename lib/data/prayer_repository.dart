import 'package:sqflite/sqflite.dart';
import '../domain/models/prayer_entry.dart';
import '../domain/models/prayer_type.dart';
import 'database.dart';

class PrayerRepository {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<PrayerEntry?> getEntry(String date, PrayerType type) async {
    final db = await _db;
    final rows = await db.query(
      'prayer_entries',
      where: 'date = ? AND prayer_type = ?',
      whereArgs: [date, type.name],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PrayerEntry.fromMap(rows.first);
  }

  Future<List<PrayerEntry>> getEntriesForDate(String date) async {
    final db = await _db;
    final rows = await db.query(
      'prayer_entries',
      where: 'date = ?',
      whereArgs: [date],
    );
    return rows.map(PrayerEntry.fromMap).toList();
  }

  Future<List<PrayerEntry>> getEntriesAfterDate(String afterDate) async {
    final db = await _db;
    final rows = await db.query(
      'prayer_entries',
      where: 'date > ?',
      whereArgs: [afterDate],
    );
    return rows.map(PrayerEntry.fromMap).toList();
  }

  // Increments count by 1, capped at 100. Returns the new entry.
  Future<PrayerEntry> incrementCount(String date, PrayerType type) async {
    final db = await _db;
    await db.rawInsert('''
      INSERT INTO prayer_entries (date, prayer_type, count, is_jumuah)
      VALUES (?, ?, 1, 0)
      ON CONFLICT(date, prayer_type) DO UPDATE SET
        count = MIN(count + 1, 100)
    ''', [date, type.name]);
    return (await getEntry(date, type))!;
  }

  // Decrements count by 1, min 0. Also clears is_jumuah if count reaches 0.
  Future<PrayerEntry> decrementCount(String date, PrayerType type) async {
    final db = await _db;
    final entry = await getEntry(date, type);
    if (entry == null || entry.count == 0) {
      return PrayerEntry(date: date, prayerType: type, count: 0);
    }
    final newCount = entry.count - 1;
    final newJumuah = newCount == 0 ? 0 : (entry.isJumuah ? 1 : 0);
    await db.update(
      'prayer_entries',
      {'count': newCount, 'is_jumuah': newJumuah},
      where: 'date = ? AND prayer_type = ?',
      whereArgs: [date, type.name],
    );
    return (await getEntry(date, type))!;
  }

  // Sets Dhuhr as Jumu'ah attended: count=1, is_jumuah=1.
  Future<PrayerEntry> setJumuah(String date) async {
    final db = await _db;
    await db.rawInsert('''
      INSERT INTO prayer_entries (date, prayer_type, count, is_jumuah)
      VALUES (?, 'dhuhr', 1, 1)
      ON CONFLICT(date, prayer_type) DO UPDATE SET
        count = MAX(count, 1),
        is_jumuah = 1
    ''', [date]);
    return (await getEntry(date, PrayerType.dhuhr))!;
  }

  Future<Map<String, int>> getMakeupSumsByType() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT prayer_type, SUM(MAX(0, count - 1)) as makeups
      FROM prayer_entries
      GROUP BY prayer_type
    ''');
    return {for (final r in rows) r['prayer_type'] as String: (r['makeups'] as int? ?? 0)};
  }

  Future<List<String>> getMissedDatesForType(
      PrayerType type, String afterDate, String beforeDate) async {
    final db = await _db;
    // Returns dates in range (afterDate, beforeDate) with count=0 or absent
    final rows = await db.rawQuery('''
      SELECT date FROM prayer_entries
      WHERE prayer_type = ? AND date > ? AND date < ? AND count = 0 AND is_jumuah = 0
    ''', [type.name, afterDate, beforeDate]);
    return rows.map((r) => r['date'] as String).toList();
  }

  Future<List<PrayerEntry>> getEntriesForTypeInRange(
      PrayerType type, String fromDate, String toDate) async {
    final db = await _db;
    final rows = await db.query(
      'prayer_entries',
      where: 'prayer_type = ? AND date >= ? AND date <= ?',
      whereArgs: [type.name, fromDate, toDate],
    );
    return rows.map(PrayerEntry.fromMap).toList();
  }

  Future<List<PrayerEntry>> getAllEntries() async {
    final db = await _db;
    final rows = await db.query('prayer_entries');
    return rows.map(PrayerEntry.fromMap).toList();
  }
}
