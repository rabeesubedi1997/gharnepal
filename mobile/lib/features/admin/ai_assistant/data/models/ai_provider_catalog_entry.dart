/// One credential field a provider's driver needs — mirrors
/// `AiProviderCredentialField` on web (lib/api/adminAiProviders.ts).
class AiProviderCredentialField {
  AiProviderCredentialField({required this.key, required this.label, required this.type, required this.required});

  factory AiProviderCredentialField.fromJson(Map<String, dynamic> json) {
    return AiProviderCredentialField(
      key: json['key'] as String,
      label: json['label'] as String,
      type: json['type'] as String, // text | password
      required: json['required'] as bool? ?? false,
    );
  }

  final String key;
  final String label;
  final String type;
  final bool required;
}

/// One supported AI agent kind and the credential fields its driver needs —
/// `GET /admin/ai-providers/catalog`. Includes 'custom', the
/// OpenAI-compatible escape hatch that lets an admin add any other AI agent
/// (Groq, DeepSeek, OpenRouter, a local Ollama instance, ...) without a
/// code change.
class AiProviderCatalogEntry {
  AiProviderCatalogEntry({required this.provider, required this.label, required this.fields});

  factory AiProviderCatalogEntry.fromJson(Map<String, dynamic> json) {
    return AiProviderCatalogEntry(
      provider: json['provider'] as String,
      label: json['label'] as String,
      fields: (json['fields'] as List<dynamic>)
          .map((f) => AiProviderCredentialField.fromJson(f as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final String provider;
  final String label;
  final List<AiProviderCredentialField> fields;
}
