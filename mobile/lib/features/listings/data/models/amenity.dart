/// Mirrors `AmenityResource`.
class Amenity {
  Amenity({required this.id, required this.key, required this.name, this.nameNe, this.category, this.icon});

  factory Amenity.fromJson(Map<String, dynamic> json) {
    return Amenity(
      id: json['id'] as int,
      key: json['key'] as String,
      name: json['name'] as String,
      nameNe: json['name_ne'] as String?,
      category: json['category'] as String?,
      icon: json['icon'] as String?,
    );
  }

  final int id;
  final String key;
  final String name;
  final String? nameNe;
  final String? category;
  final String? icon;
}
