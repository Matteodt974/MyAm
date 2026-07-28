import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myam/features/auth/data/auth_repository.dart';
import 'package:myam/features/auth/data/auth_response.dart';

class MockDio extends Mock implements Dio {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockDio mockDio;
  late MockFlutterSecureStorage mockStorage;
  late AuthRepository repository;

  setUp(() {
    mockDio = MockDio();
    mockStorage = MockFlutterSecureStorage();
    repository = AuthRepository(mockDio, mockStorage);

    when(() => mockStorage.readAll()).thenAnswer((_) async => {});
  });

  group('register', () {
    test('register succeeds on 200', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/auth/register'),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      await expectLater(
        repository.register('test@test.com', 'Password1', 'Test'),
        completes,
      );
    });

    test('register throws on 409', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/register'),
          message: 'DioException [bad response]: status code 409',
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 409,
            requestOptions: RequestOptions(path: '/auth/register'),
          ),
        ),
      );

      await expectLater(
        repository.register('test@test.com', 'Password1', 'Test'),
        throwsA(isA<DioException>()),
      );
    });

    test('register throws on 400', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/register'),
          message: 'DioException [bad response]: status code 400',
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 400,
            requestOptions: RequestOptions(path: '/auth/register'),
          ),
        ),
      );

      await expectLater(
        repository.register('test@test.com', 'Password1', 'Test'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('login', () {
    test('login saves tokens', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 200,
          data: <String, dynamic>{
            'accessToken': 'access-123',
            'refreshToken': 'refresh-123',
            'tokenType': 'Bearer',
            'accessExpiresIn': 3600,
            'refreshExpiresIn': 86400,
            'user': <String, dynamic>{
              'id': 1,
              'email': 'test@test.com',
              'displayName': 'Test User',
            },
          },
        ),
      );

      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      final auth = await repository.login('test@test.com', 'Password1');

      expect(auth.accessToken, 'access-123');
      expect(auth.refreshToken, 'refresh-123');
      expect(auth.user.email, 'test@test.com');
      verify(
        () => mockStorage.write(
          key: 'access_token',
          value: any(named: 'value'),
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: 'refresh_token',
          value: any(named: 'value'),
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: 'access_token_expiry',
          value: any(named: 'value'),
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: 'refresh_token_expiry',
          value: any(named: 'value'),
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: 'user_id',
          value: any(named: 'value'),
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: 'user_email',
          value: any(named: 'value'),
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: 'user_display_name',
          value: any(named: 'value'),
        ),
      ).called(1);
    });

    test('login throws on 401', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          message: 'DioException [bad response]: status code 401',
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/auth/login'),
          ),
        ),
      );

      await expectLater(
        repository.login('test@test.com', 'Password1'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('refresh', () {
    test('refresh saves tokens', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/auth/refresh'),
          statusCode: 200,
          data: <String, dynamic>{
            'accessToken': 'new-access',
            'refreshToken': 'new-refresh',
            'tokenType': 'Bearer',
            'accessExpiresIn': 3600,
            'refreshExpiresIn': 86400,
            'user': <String, dynamic>{
              'id': 1,
              'email': 'test@test.com',
              'displayName': 'Test User',
            },
          },
        ),
      );

      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      final auth = await repository.refresh('old-refresh-token');

      expect(auth.accessToken, 'new-access');
      expect(auth.refreshToken, 'new-refresh');
      verify(
        () => mockStorage.write(
          key: 'access_token',
          value: any(named: 'value'),
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: 'refresh_token',
          value: any(named: 'value'),
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: 'access_token_expiry',
          value: any(named: 'value'),
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: 'refresh_token_expiry',
          value: any(named: 'value'),
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: 'user_id',
          value: any(named: 'value'),
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: 'user_email',
          value: any(named: 'value'),
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: 'user_display_name',
          value: any(named: 'value'),
        ),
      ).called(1);
    });
  });

  group('logout', () {
    test('logout sends token + clears storage', () async {
      when(
        () => mockStorage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => 'some-refresh-token');
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/auth/logout'),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await repository.logout();

      verify(() => mockStorage.delete(key: 'access_token')).called(1);
      verify(() => mockStorage.delete(key: 'refresh_token')).called(1);
      verify(() => mockStorage.delete(key: 'access_token_expiry')).called(1);
      verify(() => mockStorage.delete(key: 'refresh_token_expiry')).called(1);
      verify(() => mockStorage.delete(key: 'user_id')).called(1);
      verify(() => mockStorage.delete(key: 'user_email')).called(1);
      verify(() => mockStorage.delete(key: 'user_display_name')).called(1);
    });

    test('logout clears even if backend fails', () async {
      when(
        () => mockStorage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => 'some-refresh-token');
      // The logout POST may not match its type param stub, but the
      // try-catch in logout ensures storage is cleared regardless.
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await repository.logout();

      // Storage must still be cleared even if the backend POST fails.
      verify(() => mockStorage.delete(key: 'access_token')).called(1);
      verify(() => mockStorage.delete(key: 'refresh_token')).called(1);
      verify(() => mockStorage.delete(key: 'access_token_expiry')).called(1);
      verify(() => mockStorage.delete(key: 'refresh_token_expiry')).called(1);
      verify(() => mockStorage.delete(key: 'user_id')).called(1);
      verify(() => mockStorage.delete(key: 'user_email')).called(1);
      verify(() => mockStorage.delete(key: 'user_display_name')).called(1);
    });

    test('logout wipes profile-scoped local data for every profile', () async {
      when(
        () => mockStorage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => 'some-refresh-token');
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/auth/logout'),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );
      when(() => mockStorage.readAll()).thenAnswer(
        (_) async => {
          'user_allergies_7': '["arachide"]',
          'user_allergies_12': '["lait"]',
          'user_diets_7': '["vegan"]',
          'trusted_items_7': '[]',
          'active_profile_id': '12',
          'preferred_output_language': 'fr',
        },
      );
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await repository.logout();

      verify(() => mockStorage.delete(key: 'user_allergies_7')).called(1);
      verify(() => mockStorage.delete(key: 'user_allergies_12')).called(1);
      verify(() => mockStorage.delete(key: 'user_diets_7')).called(1);
      verify(() => mockStorage.delete(key: 'trusted_items_7')).called(1);
      verify(() => mockStorage.delete(key: 'active_profile_id')).called(1);
      verifyNever(() => mockStorage.delete(key: 'preferred_output_language'));
    });
  });

  group('isAuthenticated', () {
    test('isAuthenticated true with valid token', () async {
      final futureExpiry = DateTime.now()
          .add(const Duration(days: 1))
          .toIso8601String();
      when(
        () => mockStorage.read(key: 'access_token_expiry'),
      ).thenAnswer((_) async => futureExpiry);
      when(
        () => mockStorage.read(key: 'access_token'),
      ).thenAnswer((_) async => 'valid-token');

      final result = await repository.isAuthenticated();

      expect(result, isTrue);
    });

    test('isAuthenticated false when expired', () async {
      // No access token expiry -> getAccessToken returns null
      when(
        () => mockStorage.read(key: 'access_token_expiry'),
      ).thenAnswer((_) async => null);

      // No refresh token expiry -> getRefreshToken returns null
      when(
        () => mockStorage.read(key: 'refresh_token_expiry'),
      ).thenAnswer((_) async => null);

      final result = await repository.isAuthenticated();

      expect(result, isFalse);
    });
  });

  group('getCurrentUser', () {
    test('getCurrentUser returns UserDto when all data present', () async {
      when(
        () => mockStorage.read(key: 'user_id'),
      ).thenAnswer((_) async => '42');
      when(
        () => mockStorage.read(key: 'user_email'),
      ).thenAnswer((_) async => 'test@test.com');
      when(
        () => mockStorage.read(key: 'user_display_name'),
      ).thenAnswer((_) async => 'Test User');

      final user = await repository.getCurrentUser();

      expect(user, isNotNull);
      expect(user!.id, 42);
      expect(user.email, 'test@test.com');
      expect(user.displayName, 'Test User');
    });

    test('getCurrentUser returns null when missing data', () async {
      when(
        () => mockStorage.read(key: 'user_id'),
      ).thenAnswer((_) async => '42');
      when(
        () => mockStorage.read(key: 'user_email'),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorage.read(key: 'user_display_name'),
      ).thenAnswer((_) async => 'Test User');

      final user = await repository.getCurrentUser();

      expect(user, isNull);
    });
  });
}
