import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/auth_response.dart';
import '../network/dio_client.dart';

sealed class AuthState {
  const AuthState();
}

class AuthStateAuthenticated extends AuthState {
  const AuthStateAuthenticated(this.user);

  final UserDto user;
}

class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

final authStateProvider = AsyncNotifierProvider<AuthStateNotifier, AuthState>(
  AuthStateNotifier.new,
);

class AuthStateNotifier extends AsyncNotifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<AuthState> build() async {
    final isAuthenticated = await _repository.isAuthenticated();
    if (!isAuthenticated) {
      return const AuthStateUnauthenticated();
    }

    final user = await _repository.getCurrentUser();
    if (user == null) {
      return const AuthStateUnauthenticated();
    }

    return AuthStateAuthenticated(user);
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _repository.login(email, password);
      return AuthStateAuthenticated(response.user);
    });
  }

  Future<void> register(String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _repository.register(email, password, displayName);
      return AuthStateAuthenticated(response.user);
    });
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(AuthStateUnauthenticated());
  }
}
