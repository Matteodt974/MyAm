import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myam/core/network/dio_client.dart';
import 'package:myam/core/providers/auth_state_provider.dart';
import 'package:myam/features/auth/data/auth_repository.dart';
import 'package:myam/features/auth/data/auth_response.dart';

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

  group('AuthStateNotifier', () {
    test('build returns Authenticated when user is authenticated', () async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => true);
      when(() => mockRepository.getCurrentUser()).thenAnswer(
        (_) async =>
            UserDto(id: 1, email: 'test@test.com', displayName: 'Test'),
      );

      final container = createContainer();
      addTearDown(container.dispose);

      final state = await container.read(authStateProvider.future);

      expect(state, isA<AuthStateAuthenticated>());
      final authenticated = state as AuthStateAuthenticated;
      expect(authenticated.user.id, 1);
      expect(authenticated.user.email, 'test@test.com');
    });

    test('build returns Unauthenticated when not authenticated', () async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      addTearDown(container.dispose);

      final state = await container.read(authStateProvider.future);

      expect(state, isA<AuthStateUnauthenticated>());
    });

    test('login sets state to Authenticated', () async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      addTearDown(container.dispose);

      // Let the build complete (unauthenticated).
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

      await container
          .read(authStateProvider.notifier)
          .login('test@test.com', 'Password1');

      final state = container.read(authStateProvider);
      expect(state.value, isA<AuthStateAuthenticated>());
      final authenticated = state.value as AuthStateAuthenticated;
      expect(authenticated.user.email, 'test@test.com');
    });

    test('logout resets to Unauthenticated', () async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => true);
      when(() => mockRepository.getCurrentUser()).thenAnswer(
        (_) async =>
            UserDto(id: 1, email: 'test@test.com', displayName: 'Test'),
      );

      final container = createContainer();
      addTearDown(container.dispose);

      // Let the build complete (authenticated).
      await container.read(authStateProvider.future);

      when(() => mockRepository.logout()).thenAnswer((_) async {});

      await container.read(authStateProvider.notifier).logout();

      final state = container.read(authStateProvider);
      expect(state.value, isA<AuthStateUnauthenticated>());
    });
  });
}
