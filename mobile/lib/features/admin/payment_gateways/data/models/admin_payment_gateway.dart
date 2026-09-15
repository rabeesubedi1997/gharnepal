/// One credential field's current value — never a real secret (a
/// `password`-type field only ever reports `configured`, never `value`).
/// Mirrors `GatewayCredentialValue` on web.
class GatewayCredentialValue {
  GatewayCredentialValue({required this.value, required this.configured});

  factory GatewayCredentialValue.fromJson(Map<String, dynamic> json) {
    return GatewayCredentialValue(value: json['value'] as String?, configured: json['configured'] as bool? ?? false);
  }

  final String? value;
  final bool configured;
}

/// One configured merchant account — mirrors `AdminPaymentGateway` on web.
class AdminPaymentGateway {
  AdminPaymentGateway({
    required this.id,
    required this.provider,
    required this.label,
    required this.isEnabled,
    required this.isSandbox,
    required this.sortOrder,
    required this.instructions,
    required this.credentials,
  });

  factory AdminPaymentGateway.fromJson(Map<String, dynamic> json) {
    return AdminPaymentGateway(
      id: json['id'] as int,
      provider: json['provider'] as String,
      label: json['label'] as String,
      isEnabled: json['is_enabled'] as bool? ?? false,
      isSandbox: json['is_sandbox'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      instructions: json['instructions'] as String?,
      credentials: (json['credentials'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, GatewayCredentialValue.fromJson(value as Map<String, dynamic>)),
      ),
    );
  }

  final int id;
  final String provider; // sandbox | manual | esewa | khalti | imepay | paypal
  final String label;
  final bool isEnabled;
  final bool isSandbox;
  final int sortOrder;
  final String? instructions;
  final Map<String, GatewayCredentialValue> credentials;
}
