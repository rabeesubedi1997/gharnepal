/// Mirrors `PublicPaymentGatewayResource` — one way the buyer can pay,
/// never any credentials (those never leave the admin API).
class PaymentGatewayOption {
  PaymentGatewayOption({
    required this.id,
    required this.provider,
    required this.label,
    required this.isSandbox,
  });

  factory PaymentGatewayOption.fromJson(Map<String, dynamic> json) {
    return PaymentGatewayOption(
      id: json['id'] as int,
      provider: json['provider'] as String,
      label: json['label'] as String,
      isSandbox: json['is_sandbox'] as bool? ?? false,
    );
  }

  final int id;
  final String provider; // sandbox | manual | esewa | khalti | imepay | paypal
  final String label;
  final bool isSandbox;
}
