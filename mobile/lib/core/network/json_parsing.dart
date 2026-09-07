/// Laravel serializes Eloquent `decimal:N` casts (price, area, lat/lng, etc.)
/// as JSON strings, not numbers, e.g. `"area_sqm": "2034.88"` — only plain
/// numeric-column fields come through as bare JSON numbers. Every model in
/// this app must parse decimal-backed fields through these helpers instead
/// of a raw `as num` cast, which throws on a string.
double? asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

double asDoubleOr(dynamic value, double fallback) => asDouble(value) ?? fallback;

int? asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  return null;
}
