import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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
        raw_json TEXT NOT NULL,
        profile_id INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await addProfileIdColumnIfMissing(db);
    }
  }

  /// Adds the v2 profile scope column when upgrading a genuine v1 database.
  ///
  /// Some development builds created [profile_id] while still recording
  /// schema version 1. Checking the actual table makes the migration safe for
  /// those databases and preserves their existing history.
  @visibleForTesting
  static Future<void> addProfileIdColumnIfMissing(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(scan_history)');
    final hasProfileId = columns.any(
      (column) => column['name'] == 'profile_id',
    );
    if (!hasProfileId) {
      await db.execute(
        'ALTER TABLE scan_history ADD COLUMN profile_id INTEGER',
      );
    }
  }

  /// Inserts a new entry scoped to [profileId] and returns it with the
  /// assigned [id].
  Future<ScanHistoryEntry> insert(ScanHistoryEntry entry, int profileId) async {
    final db = await database;
    final id = await db.insert('scan_history', _toMap(entry, profileId));
    return entry.copyWith(id: id);
  }

  /// Returns every entry belonging to [profileId], ordered from newest to
  /// oldest.
  Future<List<ScanHistoryEntry>> getAll(int profileId) async {
    final db = await database;
    final maps = await db.query(
      'scan_history',
      where: 'profile_id = ?',
      whereArgs: [profileId],
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
    required int profileId,
    DateTime? from,
    DateTime? to,
    List<ScanType>? types,
    List<String>? riskLevels,
    String? allergen,
  }) async {
    final db = await database;
    final where = <String>['profile_id = ?'];
    final whereArgs = <Object?>[profileId];

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
      where.add('matched_allergens LIKE ?');
      whereArgs.add('%$allergen%');
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

  /// Returns the entry with the given [id] belonging to [profileId], or null
  /// if not found.
  Future<ScanHistoryEntry?> getById(int id, int profileId) async {
    final db = await database;
    final maps = await db.query(
      'scan_history',
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, profileId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Deletes the entry with the given [id] belonging to [profileId].
  Future<void> delete(int id, int profileId) async {
    final db = await database;
    await db.delete(
      'scan_history',
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, profileId],
    );
  }

  /// Deletes every entry belonging to [profileId].
  Future<void> deleteAll(int profileId) async {
    final db = await database;
    await db.delete(
      'scan_history',
      where: 'profile_id = ?',
      whereArgs: [profileId],
    );
  }

  /// Deletes every entry for every profile.
  Future<void> deleteAllProfiles() async {
    final db = await database;
    await db.delete('scan_history');
  }

  String _placeholders(int count) {
    return List<String>.filled(count, '?').join(', ');
  }

  Map<String, Object?> _toMap(ScanHistoryEntry entry, int profileId) {
    return <String, Object?>{
      if (entry.id != null) 'id': entry.id,
      'type': entry.type.name,
      'title': entry.title,
      'scanned_at': entry.scannedAt.millisecondsSinceEpoch,
      'risk_level': entry.riskLevel,
      'matched_allergens': jsonEncode(entry.matchedAllergens),
      'thumbnail_path': entry.thumbnailPath,
      'raw_json': entry.rawJson,
      'profile_id': profileId,
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
