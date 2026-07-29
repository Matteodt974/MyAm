import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myam/features/digestive_journal/data/consent_local_store.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late ConsentLocalStore store;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    store = ConsentLocalStore(mockStorage);
  });

  group('load', () {
    test('returns false when key does not exist', () async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);

      final result = await store.load();

      expect(result, isFalse);
      verify(
        () => mockStorage.read(key: 'digestive_journal_consent'),
      ).called(1);
    });

    test("returns true when key is 'true'", () async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'true');

      final result = await store.load();

      expect(result, isTrue);
      verify(
        () => mockStorage.read(key: 'digestive_journal_consent'),
      ).called(1);
    });

    test("returns false when key is 'false'", () async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'false');

      final result = await store.load();

      expect(result, isFalse);
      verify(
        () => mockStorage.read(key: 'digestive_journal_consent'),
      ).called(1);
    });

    test('returns false on malformed data', () async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'not-a-bool');

      final result = await store.load();

      expect(result, isFalse);
    });

    test('returns false on empty string', () async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => '');

      final result = await store.load();

      expect(result, isFalse);
    });
  });

  group('save', () {
    test("save(true) writes 'true' with the correct key", () async {
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await store.save(true);

      verify(
        () =>
            mockStorage.write(key: 'digestive_journal_consent', value: 'true'),
      ).called(1);
    });
  });

  group('clear', () {
    test('deletes the correct key', () async {
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await store.clear();

      verify(
        () => mockStorage.delete(key: 'digestive_journal_consent'),
      ).called(1);
    });

    test('does NOT throw when key does not exist', () async {
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await expectLater(store.clear(), completes);

      verify(
        () => mockStorage.delete(key: 'digestive_journal_consent'),
      ).called(1);
    });
  });
}
