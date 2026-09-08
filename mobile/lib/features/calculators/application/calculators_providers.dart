import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/calculators_repository.dart';
import '../data/models/calculator_scenario.dart';

final calculatorsRepositoryProvider = Provider<CalculatorsRepository>((ref) {
  return CalculatorsRepository(apiClient: ref.watch(apiClientProvider));
});

/// First page only — a personal scenario list is realistically small (same
/// simplification used for other account list screens in this app).
final savedScenariosProvider = FutureProvider.autoDispose<List<CalculatorScenario>>((ref) {
  return ref.read(calculatorsRepositoryProvider).listScenarios();
});
