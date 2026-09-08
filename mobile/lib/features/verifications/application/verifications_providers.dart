import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/models/user_verification.dart';
import '../data/verifications_repository.dart';

final verificationsRepositoryProvider = Provider<VerificationsRepository>((ref) {
  return VerificationsRepository(apiClient: ref.watch(apiClientProvider));
});

/// Polls every 20s while watched, matching the website's `useMyVerifications`
/// — there's no push notification for when an admin approves/rejects a
/// submission.
final myVerificationsProvider = FutureProvider.autoDispose<List<UserVerification>>((ref) async {
  final repo = ref.watch(verificationsRepositoryProvider);
  final timer = Timer(const Duration(seconds: 20), () => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  return repo.list();
});
