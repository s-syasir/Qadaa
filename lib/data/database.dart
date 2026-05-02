import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _openDatabase();
    return _db!;
  }

  static const int _version = 1;

  Future<Database> _openDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'qadaa.db');
    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.rawQuery('PRAGMA journal_mode=WAL;');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE prayer_entries (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        date        TEXT    NOT NULL,
        prayer_type TEXT    NOT NULL,
        count       INTEGER NOT NULL DEFAULT 0,
        is_jumuah   INTEGER NOT NULL DEFAULT 0,
        UNIQUE(date, prayer_type)
      )
    ''');
    await db.execute('''
      CREATE TABLE initial_debt (
        prayer_type TEXT PRIMARY KEY,
        count       INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE app_settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_prayer_entries_date ON prayer_entries(date)');
    await db.execute(
        'CREATE INDEX idx_prayer_entries_type_date ON prayer_entries(prayer_type, date)');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // future migrations
  }
}
