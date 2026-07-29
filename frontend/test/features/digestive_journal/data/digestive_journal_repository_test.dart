import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myam/core/errors/api_exception.dart';
import 'package:myam/features/digestive_journal/data/digestive_journal_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late DigestiveJournalRepository repository;

  setUp(() {
    mockDio = MockDio();
    repository = DigestiveJournalRepository(mockDio);
  });

  group('create', () {
    test('envoie la date en UTC et renvoie l’entrée créée', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v1/digestive-journal'),
          statusCode: 201,
          data: <String, dynamic>{
            'id': 1,
            'bristolType': 6,
            'occurredAt': '2026-07-26T08:00:00Z',
            'notes': 'crampes',
            'createdAt': '2026-07-26T08:05:00Z',
          },
        ),
      );

      final entry = await repository.create(
        profileId: 7,
        bristolType: 6,
        occurredAt: DateTime.utc(2026, 7, 26, 8),
        notes: 'crampes',
      );

      expect(entry.id, 1);
      expect(entry.bristolType, 6);
      expect(entry.notes, 'crampes');

      final captured =
          verify(
                () => mockDio.post<Map<String, dynamic>>(
                  any(),
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['bristolType'], 6);
      expect(captured['profileId'], 7);
      expect(captured['occurredAt'], '2026-07-26T08:00:00.000Z');
      expect(captured['notes'], 'crampes');
    });

    test('omet les notes vides', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v1/digestive-journal'),
          statusCode: 201,
          data: <String, dynamic>{
            'id': 2,
            'bristolType': 4,
            'occurredAt': '2026-07-26T08:00:00Z',
            'createdAt': '2026-07-26T08:00:00Z',
          },
        ),
      );

      await repository.create(
        profileId: 7,
        bristolType: 4,
        occurredAt: DateTime.utc(2026, 7, 26, 8),
        notes: '   ',
      );

      final captured =
          verify(
                () => mockDio.post<Map<String, dynamic>>(
                  any(),
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured.containsKey('notes'), isFalse);
    });

    test('convertit une DioException en ApiException', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/digestive-journal'),
          type: DioExceptionType.connectionError,
        ),
      );

      await expectLater(
        repository.create(
          profileId: 7,
          bristolType: 4,
          occurredAt: DateTime.utc(2026),
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('list', () {
    test('désérialise les entrées renvoyées', () async {
      when(
        () => mockDio.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: RequestOptions(path: '/v1/digestive-journal'),
          statusCode: 200,
          data: <dynamic>[
            <String, dynamic>{
              'id': 1,
              'bristolType': 2,
              'occurredAt': '2026-07-26T08:00:00Z',
              'createdAt': '2026-07-26T08:00:00Z',
            },
          ],
        ),
      );

      final entries = await repository.list(profileId: 7);

      expect(entries, hasLength(1));
      expect(entries.first.bristolType, 2);
      expect(entries.first.notes, isNull);
    });

    test('renvoie une liste vide si le corps est nul', () async {
      when(
        () => mockDio.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: RequestOptions(path: '/v1/digestive-journal'),
          statusCode: 200,
        ),
      );

      expect(await repository.list(profileId: 7), isEmpty);
    });
  });
}
