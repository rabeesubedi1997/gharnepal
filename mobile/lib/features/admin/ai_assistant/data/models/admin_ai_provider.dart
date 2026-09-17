/// One credential field's current value — never a real secret (a
/// `password`-type field only ever reports `configured`, never `value`).
/// Mirrors `AiProviderCredentialValue` on web.
class AiProviderCredentialValue {
  AiProviderCredentialValue({required this.value, required this.configured});

  factory AiProviderCredentialValue.fromJson(Map<String, dynamic> json) {
    return AiProviderCredentialValue(value: json['value'] as String?, configured: json['configured'] as bool? ?? false);
  }

  final String? value;
  final bool configured;
}

/// One configured AI agent — mirrors `AdminAiProviderConfig` on web.
class AdminAiProvider {
  AdminAiProvider({required this.id, required this.provider, required this.label, required this.isEnabled, required this.credentials});

  factory AdminAiProvider.fromJson(Map<String, dynamic> json) {
    return AdminAiProvider(
      id: json['id'] as int,
      provider: json['provider'] as String,
      label: json['label'] as String,
      isEnabled: json['is_enabled'] as bool? ?? false,
      credentials: (json['credentials'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, AiProviderCredentialValue.fromJson(value as Map<String, dynamic>)),
      ),
    );
  }

  final int id;
  final String provider; // claude | openai | gemini | custom
  final String label;
  final bool isEnabled;
  final Map<String, AiProviderCredentialValue> credentials;
}

/// Another config the server auto-disabled because only one AI agent can be
/// active at a time — reported back so the UI can surface a clear message
/// instead of silently switching.
class DisabledOtherProvider {
  DisabledOtherProvider({required this.id, required this.provider, required this.label});

  factory DisabledOtherProvider.fromJson(Map<String, dynamic> json) {
    return DisabledOtherProvider(id: json['id'] as int, provider: json['provider'] as String, label: json['label'] as String);
  }

  final int id;
  final String provider;
  final String label;
}

/// The full response of a create/update call: the saved config, plus
/// whichever other configs got switched off as a side effect.
class AiProviderMutationResult {
  AiProviderMutationResult({required this.config, required this.disabledOthers});

  final AdminAiProvider config;
  final List<DisabledOtherProvider> disabledOthers;
}
