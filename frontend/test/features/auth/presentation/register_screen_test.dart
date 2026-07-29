import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myam/core/network/dio_client.dart';
import 'package:myam/features/auth/data/auth_repository.dart';
import 'package:myam/features/auth/presentation/register_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// Builds a test app wrapping [child] with a [ProviderScope] and [MaterialApp.router].
/// Overrides [authRepositoryProvider] with the given [mockRepository].
Widget createTestApp({
  required Widget child,
  required MockAuthRepository mockRepository,
  String initialLocation = '/register',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('Login')),
      ),
      GoRoute(path: '/register', builder: (_, _) => child),
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

  group('RegisterScreen', () {
    testWidgets('renders all 4 fields', (tester) async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(
        createTestApp(
          child: const RegisterScreen(),
          mockRepository: mockRepository,
        ),
      );
      await tester.pump();

      expect(
        find.widgetWithText(TextField, "Nom d'utilisateur"),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Mot de passe'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Confirmer le mot de passe'),
        findsOneWidget,
      );
    });

    testWidgets('shows error on password mismatch', (tester) async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(
        createTestApp(
          child: const RegisterScreen(),
          mockRepository: mockRepository,
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, "Nom d'utilisateur"),
        'Test',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Mot de passe'),
        'Password1',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirmer le mot de passe'),
        'Different1',
      );
      await tester.tap(find.text("S'inscrire"));
      await tester.pump();

      expect(
        find.text('Les mots de passe ne correspondent pas.'),
        findsOneWidget,
      );
    });

    testWidgets('calls register on submit', (tester) async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => false);
      when(
        () => mockRepository.register(any(), any(), any()),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        createTestApp(
          child: const RegisterScreen(),
          mockRepository: mockRepository,
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, "Nom d'utilisateur"),
        'Test',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Mot de passe'),
        'Password1',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirmer le mot de passe'),
        'Password1',
      );
      await tester.tap(find.text("S'inscrire"));
      await tester.pump();

      verify(
        () => mockRepository.register('test@test.com', 'Password1', 'Test'),
      ).called(1);
    });

    testWidgets('navigates to login on success', (tester) async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => false);
      when(
        () => mockRepository.register(any(), any(), any()),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        createTestApp(
          child: const RegisterScreen(),
          mockRepository: mockRepository,
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, "Nom d'utilisateur"),
        'Test',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Mot de passe'),
        'Password1',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirmer le mot de passe'),
        'Password1',
      );
      await tester.tap(find.text("S'inscrire"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // After successful registration, the screen navigates to /login.
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => false);

      final completer = Completer<void>();
      when(
        () => mockRepository.register(any(), any(), any()),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        createTestApp(
          child: const RegisterScreen(),
          mockRepository: mockRepository,
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, "Nom d'utilisateur"),
        'Test',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Mot de passe'),
        'Password1',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirmer le mot de passe'),
        'Password1',
      );
      await tester.tap(find.text("S'inscrire"));
      await tester.pump();

      // The button should be disabled and show a CircularProgressIndicator.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the pending operation so the test can finish cleanly.
      completer.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
