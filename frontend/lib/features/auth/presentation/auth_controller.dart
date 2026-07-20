import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_state_provider.dart';

class AuthFormState {
  const AuthFormState({
    this.isLoading = false,
    this.errorMessage,
  });

  final bool isLoading;
  final String? errorMessage;

  AuthFormState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthFormState>(AuthController.new);

class AuthController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() {
    return const AuthFormState();
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await ref.read(authStateProvider.notifier).login(email, password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _formatError(e),
      );
      return false;
    }
  }

  Future<bool> register(
    String email,
    String password,
    String displayName,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await ref
          .read(authStateProvider.notifier)
          .register(email, password, displayName);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _formatError(e),
      );
      return false;
    }
  }

  String _formatError(Object error) {
    final message = error.toString();
    if (message.contains('409') || message.contains('déjà utilisé')) {
      return 'Cet email est déjà utilisé.';
    }
    if (message.contains('400') || message.contains('Mot de passe invalide')) {
      return 'Mot de passe invalide : 8 caractères, 1 majuscule, 1 minuscule, 1 chiffre.';
    }
    if (message.contains('401') || message.contains('UNAUTHORIZED')) {
      return 'Email ou mot de passe invalide.';
    }
    return 'Une erreur est survenue. Réessaie.';
  }
}
