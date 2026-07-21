import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myam/core/network/dio_client.dart';
import 'package:myam/core/providers/auth_state_provider.dart';
import 'package:myam/features/auth/data/auth_repository.dart';
import 'package:myam/features/auth/data/auth_response.dart';
import 'package:myam/features/auth/presentation/auth_controller.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
    );
  }

  group('AuthController', () {
    test('login sets loading then success', () async {
      // Build: unauthenticated
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);

      when(() => mockRepository.login(any(), any())).thenAnswer(
        (_) async => AuthResponse(
          accessToken: 'access-123',
          refreshToken: 'refresh-123',
          tokenType: 'Bearer',
          accessExpiresIn: 3600,
          refreshExpiresIn: 86400,
          user: UserDto(id: 1, email: 'test@test.com', displayName: 'Test'),
        ),
      );

      final success = await container
          .read(authControllerProvider.notifier)
          .login('test@test.com', 'Password1');

      expect(success, isTrue);
      final state = container.read(authControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('login sets loading then error (401)', () async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);

      when(() => mockRepository.login(any(), any())).thenThrow(
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

      final success = await container
          .read(authControllerProvider.notifier)
          .login('test@test.com', 'wrong');

      expect(success, isFalse);
      final state = container.read(authControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, 'Email ou mot de passe invalide.');
    });

    test('register sets loading then success', () async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);

      when(
        () => mockRepository.register(any(), any(), any()),
      ).thenAnswer((_) async {});

      final success = await container
          .read(authControllerProvider.notifier)
          .register('test@test.com', 'Password1', 'Test');

      expect(success, isTrue);
      final state = container.read(authControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('register sets loading then error (409)', () async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);

      when(() => mockRepository.register(any(), any(), any())).thenThrow(
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

      final success = await container
          .read(authControllerProvider.notifier)
          .register('test@test.com', 'Password1', 'Test');

      expect(success, isFalse);
      final state = container.read(authControllerProvider);
      expect(state.errorMessage, 'Cet email est déjà utilisé.');
    });

    test('register sets loading then error (400)', () async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);

      when(() => mockRepository.register(any(), any(), any())).thenThrow(
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

      final success = await container
          .read(authControllerProvider.notifier)
          .register('test@test.com', 'Password1', 'Test');

      expect(success, isFalse);
      final state = container.read(authControllerProvider);
      expect(
        state.errorMessage,
        'Mot de passe invalide : 8 caractères, 1 majuscule, 1 minuscule, 1 chiffre.',
      );
    });

    test('reset clears state', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      controller.setError('Some error');
      expect(container.read(authControllerProvider).errorMessage, 'Some error');

      controller.reset();

      expect(container.read(authControllerProvider), const AuthFormState());
    });

    test('setError sets the error message', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      container.read(authControllerProvider.notifier).setError('Test error');

      final state = container.read(authControllerProvider);
      expect(state.errorMessage, 'Test error');
      expect(state.isLoading, isFalse);
    });
  });
}
