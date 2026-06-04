import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'database.dart';
import 'settings_repository.dart';

enum ExportResult { success, cancelled, permissionDenied, error }

enum ImportResult { success, cancelled, invalidFile, error }

class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  final _settings = SettingsRepository();
  static const _settingsKey = 'export_folder';

  // Default: /storage/emulated/0/Download/Qadaa
  static const String defaultFolder = '/storage/emulated/0/Download/Qadaa';

  Future<String> getExportFolder() async {
    return (await _settings.get(_settingsKey)) ?? defaultFolder;
  }

  /// Opens the system directory picker and persists the choice.
  /// Requires storage permission to be granted first.
  Future<void> setFolder(String path) async {
    await _settings.set(_settingsKey, path);
  }

  /// Checks whether we have permission to write to public storage.
  Future<bool> hasStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted) return true;
    // Android ≤ 9: legacy WRITE permission is enough
    if (await Permission.storage.isGranted) return true;
    return false;
  }

  /// Requests storage permission. Returns true if granted.
  Future<bool> requestStoragePermission() async {
    // Android 11+ requires MANAGE_EXTERNAL_STORAGE (sent to system settings).
    final manage = await Permission.manageExternalStorage.request();
    if (manage.isGranted) return true;
    // Android ≤ 9 fallback
    final legacy = await Permission.storage.request();
    return legacy.isGranted;
  }

  /// Copies qadaa.db to the export folder.
  Future<ExportResult> exportNow() async {
    if (!await hasStoragePermission()) {
      return ExportResult.permissionDenied;
    }
    try {
      // Flush all WAL writes into the main db file before copying.
      final db = await DatabaseHelper.instance.database;
      await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE);');

      final folder = await getExportFolder();
      final dir = Directory(folder);
      if (!dir.existsSync()) dir.createSync(recursive: true);

      final dbDir = await getDatabasesPath();
      final src = File(p.join(dbDir, 'qadaa.db'));
      final dst = File(p.join(folder, 'qadaa.db'));
      final bytes = await src.readAsBytes();
      await dst.writeAsBytes(bytes, flush: true);

      return ExportResult.success;
    } catch (_) {
      return ExportResult.error;
    }
  }

  Future<ImportResult> importNow() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select qadaa.db backup',
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) return ImportResult.cancelled;

    final srcPath = result.files.single.path;
    if (srcPath == null) return ImportResult.error;
    if (!srcPath.endsWith('.db')) return ImportResult.invalidFile;

    try {
      await DatabaseHelper.instance.close();

      final dbDir = await getDatabasesPath();
      final dbPath = p.join(dbDir, 'qadaa.db');

      // Remove stale WAL/SHM so the restored db opens cleanly
      for (final suffix in ['-wal', '-shm']) {
        final f = File('$dbPath$suffix');
        if (f.existsSync()) f.deleteSync();
      }

      await File(srcPath).copy(dbPath);
      return ImportResult.success;
    } catch (_) {
      return ImportResult.error;
    }
  }

  Future<void> resetFolder() => _settings.delete(_settingsKey);
}
