import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../data/models/admin_security.dart';
import '../data/security_repository.dart';

final securityRepositoryProvider = Provider<SecurityRepository>((ref) {
  return SecurityRepository(apiClient: ref.watch(apiClientProvider));
});

final adminSecurityProvider = FutureProvider.autoDispose<AdminSecurity>((ref) {
  return ref.watch(securityRepositoryProvider).get();
});
