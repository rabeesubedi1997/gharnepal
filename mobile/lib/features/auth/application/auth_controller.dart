import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/auth_events.dart';
import '../../../core/network/providers.dart';
import '../data/auth_repository.dart';
import '../data/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

/// Holds the current session: `AsyncValue<AuthUser?>` mirrors the website's
/// `useCurrentUser` — loading while resolving, `null` data for a guest, an
/// error only for genuine failures (never for "not logged in").
///
/// go_router's redirect logic (core/router/app_router.dart) reads this
/// directly to decide between the splash, login, and home shells — the
/// same job frontend/src/components/auth/RequireAuth.tsx does on the web.
class AuthController extends AsyncNotifier<AuthUser?> {
  StreamSubscription<void>? _unauthorizedSub;

  @override
  Future<AuthUser?> build() async {
    _unauthorizedSub?.cancel();
    _unauthorizedSub = AuthEvents.onUnauthorized.listen((_) {
      // A 401 from anywhere in the app means the token is no longer valid
      // (revoked, expired, or the account was suspended) — drop the session
      // without another network round-trip.
      final storage = ref.read(tokenStorageProvider);
      storage.clearToken();
      state = const AsyncData(null);
    });
    ref.onDispose(() => _unauthorizedSub?.cancel());

    final token = await ref.read(tokenStorageProvider).readToken();
    if (token == null) return null;

    return ref.read(authRepositoryProvider).me();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
      ),
    );
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email: email, password: password),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  /// Re-fetches `/auth/me` and swaps in the fresh copy — used after Settings
  /// mutations (profile name, phone verification) that change fields on the
  /// cached `AuthUser` without a full login/logout cycle. Errors are ignored:
  /// the mutation itself already succeeded, so a transient refresh failure
  /// shouldn't undo that or force a loading spinner over the whole app.
  Future<void> refreshUser() async {
    final fresh = await AsyncValue.guard(() => ref.read(authRepositoryProvider).me());
    fresh.whenData((user) => state = AsyncData(user));
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);
