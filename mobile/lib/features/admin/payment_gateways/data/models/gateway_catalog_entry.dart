/// One credential field a provider's driver needs — mirrors
/// `GatewayCredentialField` on web (lib/api/adminPaymentGateways.ts).
class GatewayCredentialField {
  GatewayCredentialField({required this.key, required this.label, required this.type, required this.required});

  factory GatewayCredentialField.fromJson(Map<String, dynamic> json) {
    return GatewayCredentialField(
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

/// One supported provider and the credential fields its driver needs —
/// `GET /admin/payment-gateways/catalog`. Static-ish: the supported
/// provider list only changes with a deploy.
class GatewayCatalogEntry {
  GatewayCatalogEntry({required this.provider, required this.label, required this.fields});

  factory GatewayCatalogEntry.fromJson(Map<String, dynamic> json) {
    return GatewayCatalogEntry(
      provider: json['provider'] as String,
      label: json['label'] as String,
      fields: (json['fields'] as List<dynamic>)
          .map((f) => GatewayCredentialField.fromJson(f as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final String provider;
  final String label;
  final List<GatewayCredentialField> fields;
}
