/// What a gateway hands back right after purchase — how to actually get the
/// buyer paying. Mirrors `FeaturedListingController::store`'s `checkout` key.
///
/// - 'inline'    — sandbox (simulate success/failure) or manual (read the
///                 instructions, wait for the admin to confirm by hand).
/// - 'redirect'/'form_post' — a real gateway. `checkoutRedirectUrl` is the
///                 one URL the app needs: opened externally, the system
///                 browser follows the redirect or auto-submits the signed
///                 form itself (see PaymentCheckoutRedirectController on the
///                 backend) — no in-app WebView needed.
class CheckoutInstruction {
  CheckoutInstruction({
    required this.mode,
    this.redirectUrl,
    this.instructions,
    this.checkoutRedirectUrl,
  });

  factory CheckoutInstruction.fromJson(Map<String, dynamic> json) {
    return CheckoutInstruction(
      mode: json['mode'] as String,
      redirectUrl: json['redirect_url'] as String?,
      instructions: json['instructions'] as String?,
      checkoutRedirectUrl: json['checkout_redirect_url'] as String?,
    );
  }

  final String mode; // inline | redirect | form_post
  final String? redirectUrl;
  final String? instructions;
  final String? checkoutRedirectUrl;
}
