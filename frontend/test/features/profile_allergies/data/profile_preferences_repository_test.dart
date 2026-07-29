import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myam/core/errors/api_exception.dart';
import 'package:myam/features/profile_allergies/data/profile_preferences_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ProfilePreferencesRepository repository;

  setUp(() {
    mockDio = MockDio();
    repository = ProfilePreferencesRepository(mockDio);
  });

  test('fetch reads allergies and diets of the profile', () async {
    when(() => mockDio.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v1/profiles/7/preferences'),
        statusCode: 200,
        data: <String, dynamic>{
          'profileId': 7,
          'displayName': 'Test',
          'allergies': ['lait', 'arachide'],
          'diets': ['VEGAN'],
        },
      ),
    );

    final preferences = await repository.fetch(7);

    expect(preferences.allergies, ['arachide', 'lait']);
    expect(preferences.diets, ['VEGAN']);
    verify(
      () => mockDio.get<Map<String, dynamic>>('/v1/profiles/7/preferences'),
    ).called(1);
  });

  test('fetch tolerates missing lists', () async {
    when(() => mockDio.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v1/profiles/7/preferences'),
        statusCode: 200,
        data: <String, dynamic>{'profileId': 7},
      ),
    );

    final preferences = await repository.fetch(7);

    expect(preferences.allergies, isEmpty);
    expect(preferences.diets, isEmpty);
  });

  test('replace sends the full profile state', () async {
    when(
      () => mockDio.put<Map<String, dynamic>>(any(), data: any(named: 'data')),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v1/profiles/7/preferences'),
        statusCode: 200,
        data: <String, dynamic>{
          'allergies': ['lait'],
          'diets': <String>[],
        },
      ),
    );

    final preferences = await repository.replace(
      7,
      allergies: ['lait'],
      diets: const [],
    );

    expect(preferences.allergies, ['lait']);
    verify(
      () => mockDio.put<Map<String, dynamic>>(
        '/v1/profiles/7/preferences',
        data: {
          'allergies': ['lait'],
          'diets': <String>[],
        },
      ),
    ).called(1);
  });

  test('fetch surfaces API errors', () async {
    when(() => mockDio.get<Map<String, dynamic>>(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/v1/profiles/7/preferences'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/v1/profiles/7/preferences'),
          statusCode: 403,
        ),
      ),
    );

    expect(() => repository.fetch(7), throwsA(isA<ApiException>()));
  });
}
