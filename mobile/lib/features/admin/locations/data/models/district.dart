/// Mirrors `DistrictResource`.
class District {
  District({
    required this.id,
    required this.provinceId,
    required this.name,
    required this.nameNe,
    required this.code,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] as int,
      provinceId: json['province_id'] as int,
      name: json['name'] as String,
      nameNe: json['name_ne'] as String?,
      code: json['code'] as String,
    );
  }

  final int id;
  final int provinceId;
  final String name;
  final String? nameNe;
  final String code;
}
