import 'package:flutter_test/flutter_test.dart';
import 'package:myam/features/history/data/scan_history_database.dart';
import 'package:myam/features/history/data/scan_history_entry.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late ScanHistoryDatabase database;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Start with a fresh database file so the CREATE TABLE path is exercised.
    final dbPath = join(
      await getDatabasesPath(),
      ScanHistoryDatabase.scanHistoryDbName,
    );
    try {
      await databaseFactory.deleteDatabase(dbPath);
    } catch (_) {
      // File may not exist; that is fine.
    }
  });

  setUp(() {
    database = ScanHistoryDatabase.instance;
  });

  const profileId = 1;

  tearDown(() async {
    await database.deleteAllProfiles();
  });

  ScanHistoryEntry makeEntry({
    required ScanType type,
    required String title,
    required DateTime scannedAt,
    String? riskLevel,
    List<String> matchedAllergens = const <String>[],
  }) {
    return ScanHistoryEntry(
      type: type,
      title: title,
      scannedAt: scannedAt,
      riskLevel: riskLevel,
      matchedAllergens: matchedAllergens,
      rawJson: '{"test": true}',
    );
  }

  group('ScanHistoryDatabase', () {
    test(
      'profile migration is idempotent when column already exists',
      () async {
        final migrationDb = await databaseFactory.openDatabase(
          inMemoryDatabasePath,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, _) async {
              await db.execute('''
              CREATE TABLE scan_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                profile_id INTEGER
              )
            ''');
            },
          ),
        );
        addTearDown(migrationDb.close);

        await ScanHistoryDatabase.addProfileIdColumnIfMissing(migrationDb);

        final columns = await migrationDb.rawQuery(
          'PRAGMA table_info(scan_history)',
        );
        expect(
          columns.where((column) => column['name'] == 'profile_id'),
          hasLength(1),
        );
      },
    );

    test('profile migration adds the column to a genuine v1 table', () async {
      final migrationDb = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute('''
              CREATE TABLE scan_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT
              )
            ''');
          },
        ),
      );
      addTearDown(migrationDb.close);

      await ScanHistoryDatabase.addProfileIdColumnIfMissing(migrationDb);

      final columns = await migrationDb.rawQuery(
        'PRAGMA table_info(scan_history)',
      );
      expect(
        columns.where((column) => column['name'] == 'profile_id'),
        hasLength(1),
      );
    });

    test('insert returns the entry with an assigned id', () async {
      final entry = makeEntry(
        type: ScanType.barcode,
        title: 'Produit 1',
        scannedAt: DateTime(2025, 1, 1),
      );

      final inserted = await database.insert(entry, profileId);

      expect(inserted.id, isNotNull);
      expect(inserted.id, isPositive);
      expect(inserted.type, ScanType.barcode);
      expect(inserted.title, 'Produit 1');
    });

    test('getAll returns entries ordered from newest to oldest', () async {
      final oldest = makeEntry(
        type: ScanType.barcode,
        title: 'Oldest',
        scannedAt: DateTime(2025, 1, 1, 10, 0),
      );
      final middle = makeEntry(
        type: ScanType.barcode,
        title: 'Middle',
        scannedAt: DateTime(2025, 1, 1, 11, 0),
      );
      final newest = makeEntry(
        type: ScanType.barcode,
        title: 'Newest',
        scannedAt: DateTime(2025, 1, 1, 12, 0),
      );

      await database.insert(oldest, profileId);
      await database.insert(middle, profileId);
      await database.insert(newest, profileId);

      final entries = await database.getAll(profileId);

      expect(entries.length, 3);
      expect(entries.map((e) => e.title).toList(), [
        'Newest',
        'Middle',
        'Oldest',
      ]);
    });

    test('getFiltered filters by type correctly', () async {
      final barcode = makeEntry(
        type: ScanType.barcode,
        title: 'Barcode',
        scannedAt: DateTime(2025, 1, 1, 10, 0),
      );
      final dish = makeEntry(
        type: ScanType.dish,
        title: 'Dish',
        scannedAt: DateTime(2025, 1, 1, 11, 0),
      );
      final label = makeEntry(
        type: ScanType.label,
        title: 'Label',
        scannedAt: DateTime(2025, 1, 1, 12, 0),
      );

      await database.insert(barcode, profileId);
      await database.insert(dish, profileId);
      await database.insert(label, profileId);

      final filtered = await database.getFiltered(
        profileId: profileId,
        types: [ScanType.dish],
      );

      expect(filtered.length, 1);
      expect(filtered.single.type, ScanType.dish);
      expect(filtered.single.title, 'Dish');
    });

    test('getFiltered filters by date range correctly', () async {
      final before = makeEntry(
        type: ScanType.barcode,
        title: 'Before',
        scannedAt: DateTime(2025, 1, 1, 8, 0),
      );
      final inside = makeEntry(
        type: ScanType.barcode,
        title: 'Inside',
        scannedAt: DateTime(2025, 1, 1, 12, 0),
      );
      final after = makeEntry(
        type: ScanType.barcode,
        title: 'After',
        scannedAt: DateTime(2025, 1, 1, 18, 0),
      );

      await database.insert(before, profileId);
      await database.insert(inside, profileId);
      await database.insert(after, profileId);

      final filtered = await database.getFiltered(
        profileId: profileId,

        from: DateTime(2025, 1, 1, 9, 0),
        to: DateTime(2025, 1, 1, 17, 0),
      );

      expect(filtered.length, 1);
      expect(filtered.single.title, 'Inside');
    });

    test('delete removes the entry', () async {
      final entry = makeEntry(
        type: ScanType.barcode,
        title: 'To delete',
        scannedAt: DateTime(2025, 1, 1),
      );
      final inserted = await database.insert(entry, profileId);
      final id = inserted.id!;

      await database.delete(id, profileId);

      final found = await database.getById(id, profileId);
      expect(found, isNull);

      final remaining = await database.getAll(profileId);
      expect(remaining, isEmpty);
    });

    test('getById returns the entry or null', () async {
      final entry = makeEntry(
        type: ScanType.barcode,
        title: 'By id',
        scannedAt: DateTime(2025, 1, 1),
      );
      final inserted = await database.insert(entry, profileId);
      final id = inserted.id!;

      final found = await database.getById(id, profileId);
      expect(found, isNotNull);
      expect(found!.title, 'By id');

      final missing = await database.getById(99999, profileId);
      expect(missing, isNull);
    });

    test('deleteAll removes every entry', () async {
      await database.insert(
        makeEntry(
          type: ScanType.barcode,
          title: 'A',
          scannedAt: DateTime(2025, 1, 1),
        ),
        profileId,
      );
      await database.insert(
        makeEntry(
          type: ScanType.dish,
          title: 'B',
          scannedAt: DateTime(2025, 1, 2),
        ),
        profileId,
      );

      await database.deleteAll(profileId);

      expect(await database.getAll(profileId), isEmpty);
    });

    test('getFiltered filters by a single risk level', () async {
      final safe = makeEntry(
        type: ScanType.barcode,
        title: 'Safe',
        scannedAt: DateTime(2025, 1, 1, 10, 0),
        riskLevel: 'SAFE',
      );
      final danger = makeEntry(
        type: ScanType.barcode,
        title: 'Danger',
        scannedAt: DateTime(2025, 1, 1, 11, 0),
        riskLevel: 'DANGER',
      );

      await database.insert(safe, profileId);
      await database.insert(danger, profileId);

      final filtered = await database.getFiltered(
        profileId: profileId,
        riskLevels: ['DANGER'],
      );

      expect(filtered.length, 1);
      expect(filtered.single.title, 'Danger');
    });

    test('getFiltered filters by risk level including empty values', () async {
      final noRisk = makeEntry(
        type: ScanType.barcode,
        title: 'No risk',
        scannedAt: DateTime(2025, 1, 1, 8, 0),
      );
      final emptyRisk = makeEntry(
        type: ScanType.barcode,
        title: 'Empty risk',
        scannedAt: DateTime(2025, 1, 1, 9, 0),
        riskLevel: '',
      );
      final safe = makeEntry(
        type: ScanType.barcode,
        title: 'Safe',
        scannedAt: DateTime(2025, 1, 1, 10, 0),
        riskLevel: 'SAFE',
      );
      final danger = makeEntry(
        type: ScanType.barcode,
        title: 'Danger',
        scannedAt: DateTime(2025, 1, 1, 11, 0),
        riskLevel: 'DANGER',
      );

      await database.insert(noRisk, profileId);
      await database.insert(emptyRisk, profileId);
      await database.insert(safe, profileId);
      await database.insert(danger, profileId);

      final filtered = await database.getFiltered(
        profileId: profileId,

        riskLevels: ['', 'SAFE'],
      );

      expect(filtered.map((e) => e.title).toSet(), {
        'No risk',
        'Empty risk',
        'Safe',
      });
    });

    test('getFiltered filters by allergen substring', () async {
      final peanut = makeEntry(
        type: ScanType.barcode,
        title: 'Peanut',
        scannedAt: DateTime(2025, 1, 1, 8, 0),
        matchedAllergens: ['peanuts'],
      );
      final milk = makeEntry(
        type: ScanType.barcode,
        title: 'Milk',
        scannedAt: DateTime(2025, 1, 1, 9, 0),
        matchedAllergens: ['milk'],
      );
      final none = makeEntry(
        type: ScanType.barcode,
        title: 'None',
        scannedAt: DateTime(2025, 1, 1, 10, 0),
      );

      await database.insert(peanut, profileId);
      await database.insert(milk, profileId);
      await database.insert(none, profileId);

      final filtered = await database.getFiltered(
        profileId: profileId,
        allergen: 'milk',
      );

      expect(filtered.length, 1);
      expect(filtered.single.title, 'Milk');
    });
  });
}
