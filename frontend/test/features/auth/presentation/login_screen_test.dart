import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myam/core/network/dio_client.dart';
import 'package:myam/features/auth/data/auth_repository.dart';
import 'package:myam/features/auth/data/auth_response.dart';
import 'package:myam/features/auth/presentation/login_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// Builds a test app wrapping [child] with a [ProviderScope] and [MaterialApp.router].
/// Overrides [authRepositoryProvider] with the given [mockRepository].
Widget createTestApp({
  required Widget child,
  required MockAuthRepository mockRepository,
  String initialLocation = '/login',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(path: '/login', builder: (_, __) => child),
      GoRoute(
        path: '/register',
        builder: (_, __) => const Scaffold(body: Text('Register')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
  });

  group('LoginScreen', () {
    testWidgets('renders email and password fields', (tester) async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(
        createTestApp(
          child: const LoginScreen(),
          mockRepository: mockRepository,
        ),
      );
      await tester.pump();

      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Mot de passe'), findsOneWidget);
    });

    testWidgets('shows SnackBar when registered=true', (tester) async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(
        createTestApp(
          child: const LoginScreen(),
          mockRepository: mockRepository,
          initialLocation: '/login?registered=true',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Compte créé avec succès. Connecte-toi.'),
        findsOneWidget,
      );
    });

    testWidgets('no SnackBar without registered param', (tester) async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(
        createTestApp(
          child: const LoginScreen(),
          mockRepository: mockRepository,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Compte créé avec succès. Connecte-toi.'), findsNothing);
    });

    testWidgets('calls login on submit', (tester) async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => false);
      // Login must throw so navigation to / is skipped and the test can
      // verify the mock was called without the widget being unmounted.
      when(() => mockRepository.login(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          message: '401',
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/auth/login'),
          ),
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          child: const LoginScreen(),
          mockRepository: mockRepository,
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Mot de passe'),
        'Password1',
      );
      await tester.tap(find.text('Se connecter'));
      await tester.pump();

      verify(
        () => mockRepository.login('test@test.com', 'Password1'),
      ).called(1);
    });

    testWidgets('navigates to home on success', (tester) async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => false);
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

      await tester.pumpWidget(
        createTestApp(
          child: const LoginScreen(),
          mockRepository: mockRepository,
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Mot de passe'),
        'Password1',
      );
      await tester.tap(find.text('Se connecter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // After successful login, the screen navigates to /.
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('shows error on failure', (tester) async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => false);
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

      await tester.pumpWidget(
        createTestApp(
          child: const LoginScreen(),
          mockRepository: mockRepository,
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Mot de passe'),
        'wrong',
      );
      await tester.tap(find.text('Se connecter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Email ou mot de passe invalide.'), findsOneWidget);
    });
  });
}
