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

  tearDown(() async {
    await database.deleteAll();
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
    test('insert returns the entry with an assigned id', () async {
      final entry = makeEntry(
        type: ScanType.barcode,
        title: 'Produit 1',
        scannedAt: DateTime(2025, 1, 1),
      );

      final inserted = await database.insert(entry);

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

      await database.insert(oldest);
      await database.insert(middle);
      await database.insert(newest);

      final entries = await database.getAll();

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

      await database.insert(barcode);
      await database.insert(dish);
      await database.insert(label);

      final filtered = await database.getFiltered(types: [ScanType.dish]);

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

      await database.insert(before);
      await database.insert(inside);
      await database.insert(after);

      final filtered = await database.getFiltered(
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
      final inserted = await database.insert(entry);
      final id = inserted.id!;

      await database.delete(id);

      final found = await database.getById(id);
      expect(found, isNull);

      final remaining = await database.getAll();
      expect(remaining, isEmpty);
    });

    test('getById returns the entry or null', () async {
      final entry = makeEntry(
        type: ScanType.barcode,
        title: 'By id',
        scannedAt: DateTime(2025, 1, 1),
      );
      final inserted = await database.insert(entry);
      final id = inserted.id!;

      final found = await database.getById(id);
      expect(found, isNotNull);
      expect(found!.title, 'By id');

      final missing = await database.getById(99999);
      expect(missing, isNull);
    });

    test('deleteAll removes every entry', () async {
      await database.insert(
        makeEntry(
          type: ScanType.barcode,
          title: 'A',
          scannedAt: DateTime(2025, 1, 1),
        ),
      );
      await database.insert(
        makeEntry(
          type: ScanType.dish,
          title: 'B',
          scannedAt: DateTime(2025, 1, 2),
        ),
      );

      await database.deleteAll();

      expect(await database.getAll(), isEmpty);
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

      await database.insert(safe);
      await database.insert(danger);

      final filtered = await database.getFiltered(riskLevels: ['DANGER']);

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

      await database.insert(noRisk);
      await database.insert(emptyRisk);
      await database.insert(safe);
      await database.insert(danger);

      final filtered = await database.getFiltered(riskLevels: ['', 'SAFE']);

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

      await database.insert(peanut);
      await database.insert(milk);
      await database.insert(none);

      final filtered = await database.getFiltered(allergen: 'milk');

      expect(filtered.length, 1);
      expect(filtered.single.title, 'Milk');
    });
  });
}
