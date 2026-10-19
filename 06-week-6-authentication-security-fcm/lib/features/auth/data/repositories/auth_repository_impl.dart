import '../../../../core/failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl();

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!email.contains('@') || password.length < 6) {
        return (
          session: null,
          failure: const AuthFailure('Email atau kata sandi tidak valid'),
        );
      }
      final session = AuthSession(
        access: 'mock-access-for-$email',
        refresh: 'mock-refresh-for-$email',
      );
      return (session: session, failure: null);
    } catch (e) {
      return (
        session: null,
        failure: AuthFailure('Gagal melakukan autentikasi: $e'),
      );
    }
  }

  @override
  Future<({String? access, Failure? failure})> refresh(
    String refreshToken,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (refreshToken.isEmpty) {
        return (
          access: null,
          failure: const AuthFailure('Refresh token hilang'),
        );
      }
      return (
        access: 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}',
        failure: null,
      );
    } catch (e) {
      return (access: null, failure: AuthFailure('Gagal memperbarui sesi: $e'));
    }
  }
}
