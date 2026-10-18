import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_errors.dart';
import '../data/auth_repository.dart';
import '../data/token_store.dart';
import '../messaging/push_service.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

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
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
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
    } catch (error, stackTrace) {
      // REFACTORING: UI menerima pesan ramah, bukan exception mentah.
      state = AsyncError(apiErrorMessage(error), stackTrace);
    }
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    state = const AsyncData(false);
  }
}
