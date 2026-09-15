/// Mirrors `AdminSecuritySettings` on web (`lib/api/security.ts`) — the
/// secret key itself never comes back, only whether one is set.
class AdminSecurity {
  AdminSecurity({
    required this.recaptchaEnabled,
    required this.recaptchaSiteKey,
    required this.recaptchaSecretConfigured,
    required this.isActive,
  });

  factory AdminSecurity.fromJson(Map<String, dynamic> json) {
    return AdminSecurity(
      recaptchaEnabled: json['recaptcha_enabled'] as bool? ?? false,
      recaptchaSiteKey: json['recaptcha_site_key'] as String?,
      recaptchaSecretConfigured: json['recaptcha_secret_configured'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  final bool recaptchaEnabled;
  final String? recaptchaSiteKey;
  final bool recaptchaSecretConfigured;
  /// True only once the toggle is on AND both keys are actually set —
  /// mirrors `PlatformSecurity::captchaIsActive()` on the backend.
  final bool isActive;
}

/// Mirrors `MailTestResult` on web.
class MailTestResult {
  MailTestResult({required this.sent, required this.to, required this.mailer, this.error});

  factory MailTestResult.fromJson(Map<String, dynamic> json) {
    return MailTestResult(
      sent: json['sent'] as bool,
      to: json['to'] as String,
      mailer: json['mailer'] as String,
      error: json['error'] as String?,
    );
  }

  final bool sent;
  final String to;
  final String mailer;
  final String? error;
}
