import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'scan_history_entry.dart';

/// SQLite helper for persisting scan history entries.
///
/// Uses a single SQLite database named [scanHistoryDbName] with one table,
/// `scan_history`. The helper is exposed as a singleton via [instance].
class ScanHistoryDatabase {
  static const String scanHistoryDbName = 'scan_history.db';

  static final ScanHistoryDatabase instance = ScanHistoryDatabase._internal();

  Database? _database;

  ScanHistoryDatabase._internal();

  /// Lazily opens the database, creating/upgrading the schema if needed.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesDir = await getDatabasesPath();
    await Directory(databasesDir).create(recursive: true);
    final dbPath = join(databasesDir, scanHistoryDbName);

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scan_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        scanned_at INTEGER NOT NULL,
        risk_level TEXT,
        matched_allergens TEXT,
        thumbnail_path TEXT,
        raw_json TEXT NOT NULL
      )
    ''');
  }

  /// Inserts a new entry and returns it with the assigned [id].
  Future<ScanHistoryEntry> insert(ScanHistoryEntry entry) async {
    final db = await database;
    final id = await db.insert('scan_history', _toMap(entry));
    return entry.copyWith(id: id);
  }

  /// Returns every entry ordered from newest to oldest.
  Future<List<ScanHistoryEntry>> getAll() async {
    final db = await database;
    final maps = await db.query(
      'scan_history',
      orderBy: 'scanned_at DESC',
    );
    return maps.map(_fromMap).toList();
  }

  /// Returns entries matching all provided filters, newest first.
  ///
  /// - [from] / [to]: inclusive range on [scanned_at] (epoch milliseconds).
  /// - [types]: only these scan types.
  /// - [riskLevels]: only these risk levels. An empty string in the list
  ///   matches entries where [risk_level] is NULL or ''.
  /// - [allergen]: substring match against the JSON-encoded
  ///   [matched_allergens] column.
  Future<List<ScanHistoryEntry>> getFiltered({
    DateTime? from,
    DateTime? to,
    List<ScanType>? types,
    List<String>? riskLevels,
    String? allergen,
  }) async {
    final db = await database;
    final where = <String>[];
    final whereArgs = <Object?>[];

    if (from != null) {
      where.add('scanned_at >= ?');
      whereArgs.add(from.millisecondsSinceEpoch);
    }

    if (to != null) {
      where.add('scanned_at <= ?');
      whereArgs.add(to.millisecondsSinceEpoch);
    }

    if (types != null && types.isNotEmpty) {
      where.add('type IN (${_placeholders(types.length)})');
      whereArgs.addAll(types.map((t) => t.name));
    }

    if (riskLevels != null && riskLevels.isNotEmpty) {
      final conditions = <String>[];
      final nonEmptyLevels = riskLevels.where((r) => r.isNotEmpty).toList();

      if (nonEmptyLevels.isNotEmpty) {
        conditions.add(
          'risk_level IN (${_placeholders(nonEmptyLevels.length)})',
        );
        whereArgs.addAll(nonEmptyLevels);
      }

      if (riskLevels.any((r) => r.isEmpty)) {
        // NULL/'' represents "no risk level".
        conditions.add('(risk_level IS NULL OR risk_level = ?)');
        whereArgs.add('');
      }

      if (conditions.length == 1) {
        where.add(conditions.first);
      } else if (conditions.length > 1) {
        where.add('(${conditions.join(' OR ')})');
      }
    }

    if (allergen != null && allergen.isNotEmpty) {
      // JSON substring search is sufficient for the MVP filtering use case.
      where.add("matched_allergens LIKE '%$allergen%'");
    }

    final whereClause = where.isEmpty ? null : where.join(' AND ');
    final maps = await db.query(
      'scan_history',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'scanned_at DESC',
    );
    return maps.map(_fromMap).toList();
  }

  /// Returns the entry with the given [id], or null if not found.
  Future<ScanHistoryEntry?> getById(int id) async {
    final db = await database;
    final maps = await db.query(
      'scan_history',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Deletes the entry with the given [id].
  Future<void> delete(int id) async {
    final db = await database;
    await db.delete(
      'scan_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all entries.
  Future<void> deleteAll() async {
    final db = await database;
    await db.delete('scan_history');
  }

  String _placeholders(int count) {
    return List<String>.filled(count, '?').join(', ');
  }

  Map<String, Object?> _toMap(ScanHistoryEntry entry) {
    return <String, Object?>{
      if (entry.id != null) 'id': entry.id,
      'type': entry.type.name,
      'title': entry.title,
      'scanned_at': entry.scannedAt.millisecondsSinceEpoch,
      'risk_level': entry.riskLevel,
      'matched_allergens': jsonEncode(entry.matchedAllergens),
      'thumbnail_path': entry.thumbnailPath,
      'raw_json': entry.rawJson,
    };
  }

  ScanHistoryEntry _fromMap(Map<String, Object?> map) {
    final rawAllergens = map['matched_allergens'] as String?;
    final allergens = rawAllergens == null || rawAllergens.isEmpty
        ? const <String>[]
        : List<String>.from(jsonDecode(rawAllergens) as List<dynamic>);

    return ScanHistoryEntry(
      id: map['id'] as int?,
      type: ScanType.values.byName(map['type'] as String),
      title: map['title'] as String,
      scannedAt: DateTime.fromMillisecondsSinceEpoch(map['scanned_at'] as int),
      riskLevel: map['risk_level'] as String?,
      matchedAllergens: allergens,
      thumbnailPath: map['thumbnail_path'] as String?,
      rawJson: map['raw_json'] as String,
    );
  }
}
