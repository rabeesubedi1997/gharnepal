/// Mirrors `CostCalculatorScenarioResource` — a saved rental/purchase
/// scenario. `inputs`/`result` are kept as raw maps (their shape depends on
/// `type`) rather than being re-parsed into the typed result classes, since
/// the saved-scenarios list only needs to show a summary, not replay the
/// full breakdown UI.
class CalculatorScenario {
  CalculatorScenario({
    required this.id,
    required this.type,
    this.name,
    required this.inputs,
    required this.result,
    this.listingId,
    required this.createdAt,
  });

  factory CalculatorScenario.fromJson(Map<String, dynamic> json) {
    return CalculatorScenario(
      id: json['id'] as int,
      type: json['type'] as String,
      name: json['name'] as String?,
      inputs: json['inputs'] as Map<String, dynamic>? ?? const {},
      result: json['result'] as Map<String, dynamic>? ?? const {},
      listingId: json['listing_id'] as int?,
      createdAt: json['created_at'] as String,
    );
  }

  final int id;
  final String type; // rental | purchase
  final String? name;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> result;
  final int? listingId;
  final String createdAt;
}
