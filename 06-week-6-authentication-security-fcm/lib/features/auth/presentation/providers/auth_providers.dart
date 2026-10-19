import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../messaging/push_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/sources/token_store.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => const AuthRepositoryImpl(),
);

final loginUseCaseProvider = Provider<Login>((ref) {
  return Login(ref.watch(authRepositoryProvider));
});

final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await ref.watch(tokenStoreProvider).readAccess();
    return token != null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    final result = await ref
        .read(loginUseCaseProvider)
        .call(email: email, password: password);

    if (result.failure != null) {
      state = AsyncError(result.failure!.message, StackTrace.current);
      return;
    }

    final session = result.session!;
    await ref
        .read(tokenStoreProvider)
        .save(access: session.access, refresh: session.refresh);

    await requestNotificationPermission();
    await initFcmToken(
      onToken: (token) async {
        final preview = token.length > 12
            ? '${token.substring(0, 12)}...'
            : 'token tersedia';
        debugPrint('FCM token preview: $preview');
      },
    );

    state = const AsyncData(true);
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    state = const AsyncData(false);
  }
}
