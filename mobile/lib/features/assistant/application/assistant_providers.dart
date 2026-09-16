import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/assistant_chat_storage.dart';
import '../data/assistant_repository.dart';

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  return AssistantRepository(apiClient: ref.watch(apiClientProvider));
});

final assistantChatStorageProvider = Provider<AssistantChatStorage>((ref) => AssistantChatStorage());
