import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guest identity + conversation continuity for the AI assistant, persisted
/// the same way as [TokenStorage] — reusing the OS keystore/keychain that's
/// already a dependency rather than adding shared_preferences just for two
/// small strings.
class AssistantChatStorage {
  AssistantChatStorage({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  static const _guestTokenKey = 'assistant_guest_token';
  static const _conversationIdKey = 'assistant_conversation_id';

  final FlutterSecureStorage _storage;

  Future<String?> readGuestToken() => _storage.read(key: _guestTokenKey);

  Future<void> saveGuestToken(String token) => _storage.write(key: _guestTokenKey, value: token);

  Future<int?> readConversationId() async {
    final raw = await _storage.read(key: _conversationIdKey);
    return raw != null ? int.tryParse(raw) : null;
  }

  Future<void> saveConversationId(int id) => _storage.write(key: _conversationIdKey, value: id.toString());

  Future<void> clearConversation() => _storage.delete(key: _conversationIdKey);
}
