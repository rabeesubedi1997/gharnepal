/// Mirrors `ProvinceResource`.
class Province {
  Province({required this.id, required this.name, this.nameNe, required this.code});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      id: json['id'] as int,
      name: json['name'] as String,
      nameNe: json['name_ne'] as String?,
      code: json['code'] as String,
    );
  }

  final int id;
  final String name;
  final String? nameNe;
  final String code;
}
