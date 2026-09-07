/// Nepal land-area unit conversions, ported exactly from the backend's
/// single source of truth:
/// backend/app/Domain/Calculators/Services/AreaUnitConverter.php
///
/// Nepal listings commonly use ropani/aana in the hills (Kathmandu Valley,
/// Pokhara) and kattha/dhur in the Terai (Chitwan, Biratnagar) alongside
/// sqft/sqm. Conversion factors are Nepal's official survey department
/// constants — every screen showing or accepting an area should convert
/// through here rather than hardcoding factors.
class AreaUnitConverter {
  AreaUnitConverter._();

  static const Map<String, double> _toSqm = {
    'sqm': 1.0,
    'sqft': 0.092903,
    'aana': 31.7949,
    'ropani': 508.72,
    'kattha': 338.63,
    'dhur': 16.93,
  };

  static double toSqm(double value, String unit) {
    return _round2(value * _factor(unit));
  }

  static double fromSqm(double sqm, String unit) {
    return _round2(sqm / _factor(unit));
  }

  static double _factor(String unit) {
    final factor = _toSqm[unit];
    if (factor == null) {
      throw ArgumentError('Unknown area unit [$unit].');
    }
    return factor;
  }

  static double _round2(double value) => (value * 100).round() / 100;

  static List<String> get units => _toSqm.keys.toList(growable: false);
}
