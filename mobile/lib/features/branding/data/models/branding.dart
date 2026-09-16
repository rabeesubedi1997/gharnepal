/// Mirrors the public `GET /branding` response (`BrandingResource` on the
/// backend) — site name + whatever icons an admin has uploaded from
/// Admin > Branding. Public, no auth needed.
class Branding {
  Branding({required this.siteName, this.faviconUrl, this.appIconUrl});

  factory Branding.fromJson(Map<String, dynamic> json) {
    return Branding(
      siteName: json['site_name'] as String? ?? 'Ghar Nepal',
      faviconUrl: json['favicon_url'] as String?,
      appIconUrl: json['app_icon_url'] as String?,
    );
  }

  final String siteName;
  final String? faviconUrl;
  final String? appIconUrl;

  /// What a small in-app logo badge should show — the app icon source if
  /// one's been uploaded, else the favicon, else nothing (fall back to a
  /// plain icon glyph).
  String? get logoUrl => appIconUrl ?? faviconUrl;
}
