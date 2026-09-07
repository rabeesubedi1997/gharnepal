/// Mirrors the `poster` object on `PropertyListingDetailResource`. Note
/// there is deliberately no phone/email field — only a derived WhatsApp
/// link, and only when the poster's phone is verified.
class Poster {
  Poster({required this.name, required this.memberSince, this.agencyName, this.agencySlug, this.whatsappUrl});

  factory Poster.fromJson(Map<String, dynamic> json) {
    final agency = json['agency'] as Map<String, dynamic>?;
    return Poster(
      name: json['name'] as String,
      memberSince: json['member_since'] as String?,
      agencyName: agency?['name'] as String?,
      agencySlug: agency?['slug'] as String?,
      whatsappUrl: json['whatsapp_url'] as String?,
    );
  }

  final String name;
  final String? memberSince;
  final String? agencyName;
  final String? agencySlug;
  final String? whatsappUrl;

  bool get isAgency => agencyName != null;
}
