import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/formatters/npr_formatter.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../../auth/application/auth_controller.dart';
import '../application/calculators_providers.dart';
import '../data/models/calculator_scenario.dart';
import '../data/models/purchase_calculator_result.dart';
import '../data/models/rental_calculator_result.dart';

/// Mirrors frontend/src/pages/Calculators/{RentalCalculator,PurchaseCalculator}.tsx:
/// guests can compute freely, saving requires login. Every "save" is a fresh
/// POST with `save: true` (the backend has no separate patch-to-save step).
class CalculatorsScreen extends StatelessWidget {
  const CalculatorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Calculators'),
          bottom: const TabBar(tabs: [Tab(text: 'Rental'), Tab(text: 'Purchase'), Tab(text: 'Saved')]),
        ),
        body: const TabBarView(
          children: [_RentalCalculatorTab(), _PurchaseCalculatorTab(), _SavedScenariosTab()],
        ),
      ),
    );
  }
}

class _RentalCalculatorTab extends ConsumerStatefulWidget {
  const _RentalCalculatorTab();

  @override
  ConsumerState<_RentalCalculatorTab> createState() => _RentalCalculatorTabState();
}

class _RentalCalculatorTabState extends ConsumerState<_RentalCalculatorTab> {
  final _rentController = TextEditingController();
  final _depositMonthsController = TextEditingController(text: '2');
  final _utilitiesController = TextEditingController();
  final _internetController = TextEditingController();
  final _parkingController = TextEditingController();
  final _maintenanceController = TextEditingController();
  final _brokerageController = TextEditingController();
  final _movingController = TextEditingController();
  final _nameController = TextEditingController();

  RentalCalculatorResult? _result;
  bool _calculating = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _rentController,
      _depositMonthsController,
      _utilitiesController,
      _internetController,
      _parkingController,
      _maintenanceController,
      _brokerageController,
      _movingController,
      _nameController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.trim());

  Future<void> _calculate({bool save = false}) async {
    final rent = _num(_rentController);
    if (rent == null || rent <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a monthly rent amount.')));
      return;
    }

    setState(() => save ? _saving = true : _calculating = true);
    try {
      final calculation = await ref
          .read(calculatorsRepositoryProvider)
          .calculateRental(
            monthlyRent: rent,
            depositMonths: _num(_depositMonthsController),
            utilitiesMonthly: _num(_utilitiesController),
            internetMonthly: _num(_internetController),
            parkingMonthly: _num(_parkingController),
            maintenanceMonthly: _num(_maintenanceController),
            brokerageFee: _num(_brokerageController),
            movingCostEstimate: _num(_movingController),
            save: save,
            name: _nameController.text.trim(),
          );
      if (!mounted) return;
      setState(() => _result = calculation.result);
      if (save) {
        ref.invalidate(savedScenariosProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scenario saved.')));
      }
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => save ? _saving = false : _calculating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(authControllerProvider).valueOrNull != null;
    final result = _result;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _rentController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Monthly rent (Rs)'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _depositMonthsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Deposit (months)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _utilitiesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Utilities/mo (optional)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _internetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Internet/mo (optional)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _parkingController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Parking/mo (optional)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _maintenanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Maintenance/mo (optional)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _brokerageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Brokerage fee (optional)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _movingController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Moving cost estimate (optional)'),
        ),
        const SizedBox(height: 16),
        AppButton(label: 'Calculate', isLoading: _calculating, onPressed: () => _calculate()),
        if (result != null) ...[
          const SizedBox(height: 20),
          _ResultCard(
            rows: [
              ('Monthly rent', result.monthlyRent),
              ('Utilities', result.utilitiesMonthly),
              ('Internet', result.internetMonthly),
              ('Parking', result.parkingMonthly),
              ('Maintenance', result.maintenanceMonthly),
            ],
            highlights: [
              ('Monthly recurring total', result.monthlyRecurringTotal),
              ('Deposit', result.deposit),
              ('One-time costs (deposit + brokerage + moving)', result.oneTimeTotal),
              ('First month total', result.firstMonthTotal),
            ],
          ),
          const SizedBox(height: 16),
          if (loggedIn) ...[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name this scenario (optional)'),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Save this scenario',
              variant: AppButtonVariant.outlined,
              isLoading: _saving,
              onPressed: () => _calculate(save: true),
            ),
          ] else
            Text(
              'Log in to save this scenario for later.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
            ),
        ],
      ],
    );
  }
}

class _PurchaseCalculatorTab extends ConsumerStatefulWidget {
  const _PurchaseCalculatorTab();

  @override
  ConsumerState<_PurchaseCalculatorTab> createState() => _PurchaseCalculatorTabState();
}

class _PurchaseCalculatorTabState extends ConsumerState<_PurchaseCalculatorTab> {
  final _priceController = TextEditingController();
  final _downPaymentController = TextEditingController(text: '20');
  final _interestController = TextEditingController(text: '10');
  final _tenureController = TextEditingController(text: '20');
  final _registrationController = TextEditingController(text: '4');
  final _legalFeesController = TextEditingController();
  final _renovationController = TextEditingController();
  final _rentEstimateController = TextEditingController();
  final _nameController = TextEditingController();

  PurchaseCalculatorResult? _result;
  bool _calculating = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _priceController,
      _downPaymentController,
      _interestController,
      _tenureController,
      _registrationController,
      _legalFeesController,
      _renovationController,
      _rentEstimateController,
      _nameController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.trim());

  Future<void> _calculate({bool save = false}) async {
    final price = _num(_priceController);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a property price.')));
      return;
    }

    setState(() => save ? _saving = true : _calculating = true);
    try {
      final calculation = await ref
          .read(calculatorsRepositoryProvider)
          .calculatePurchase(
            propertyPrice: price,
            downPaymentPercent: _num(_downPaymentController),
            loanInterestRateAnnual: _num(_interestController),
            loanTenureYears: _num(_tenureController),
            registrationCostPercent: _num(_registrationController),
            legalFees: _num(_legalFeesController),
            renovationEstimate: _num(_renovationController),
            monthlyRentEstimate: _num(_rentEstimateController),
            save: save,
            name: _nameController.text.trim(),
          );
      if (!mounted) return;
      setState(() => _result = calculation.result);
      if (save) {
        ref.invalidate(savedScenariosProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scenario saved.')));
      }
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => save ? _saving = false : _calculating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(authControllerProvider).valueOrNull != null;
    final result = _result;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Property price (Rs)'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _downPaymentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Down payment (%)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _interestController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Interest rate (% p.a.)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tenureController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Loan tenure (years)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _registrationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Registration cost (%)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _legalFeesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Legal fees (optional)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _renovationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Renovation est. (optional)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _rentEstimateController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Expected monthly rent (optional)',
            helperText: 'Used only to estimate rental yield if you plan to rent this out.',
          ),
        ),
        const SizedBox(height: 16),
        AppButton(label: 'Calculate', isLoading: _calculating, onPressed: () => _calculate()),
        if (result != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppColors.warning100, borderRadius: BorderRadius.circular(8)),
            child: const Text(
              'Registration and legal costs are estimates — actual rates vary by province and declared value. This is not a legal quote.',
              style: TextStyle(color: AppColors.warning600),
            ),
          ),
          _ResultCard(
            rows: [
              ('Property price', result.propertyPrice),
              ('Down payment', result.downPayment),
              ('Loan amount', result.loanAmount),
              ('Registration cost', result.registrationCost),
              ('Legal fees', result.legalFees),
              ('Renovation estimate', result.renovationEstimate),
            ],
            highlights: [
              ('Estimated monthly repayment (EMI)', result.monthlyRepaymentEstimate),
              ('Total upfront cost', result.totalUpfrontCost),
              if (result.rentalYieldPercent != null) ('Estimated rental yield', null),
            ],
            rentalYieldPercent: result.rentalYieldPercent,
          ),
          const SizedBox(height: 16),
          if (loggedIn) ...[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name this scenario (optional)'),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Save this scenario',
              variant: AppButtonVariant.outlined,
              isLoading: _saving,
              onPressed: () => _calculate(save: true),
            ),
          ] else
            Text(
              'Log in to save this scenario for later.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
            ),
        ],
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.rows, required this.highlights, this.rentalYieldPercent});

  final List<(String, double)> rows;
  final List<(String, double?)> highlights;
  final double? rentalYieldPercent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final row in rows) _line(context, row.$1, NprFormatter.format(row.$2)),
            const Divider(height: 20),
            for (final row in highlights)
              _line(
                context,
                row.$1,
                row.$2 != null
                    ? NprFormatter.format(row.$2!)
                    : '${rentalYieldPercent?.toStringAsFixed(2)}%',
                emphasize: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value, {bool emphasize = false}) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.trust700)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _SavedScenariosTab extends ConsumerWidget {
  const _SavedScenariosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authControllerProvider).valueOrNull != null;

    if (!loggedIn) {
      return Center(
        child: FilledButton(onPressed: () => context.push('/login'), child: const Text('Log in to view saved scenarios')),
      );
    }

    final scenarios = ref.watch(savedScenariosProvider);

    return scenarios.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        message: 'Could not load your saved scenarios.',
        onRetry: () => ref.invalidate(savedScenariosProvider),
      ),
      data: (items) => items.isEmpty
          ? const EmptyState(title: 'No saved scenarios yet', icon: Icons.calculate_outlined)
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(savedScenariosProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (context, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _ScenarioTile(scenario: items[index]),
              ),
            ),
    );
  }
}

class _ScenarioTile extends ConsumerStatefulWidget {
  const _ScenarioTile({required this.scenario});

  final CalculatorScenario scenario;

  @override
  ConsumerState<_ScenarioTile> createState() => _ScenarioTileState();
}

class _ScenarioTileState extends ConsumerState<_ScenarioTile> {
  bool _deleting = false;

  static final _dateFormat = DateFormat('d MMM y');

  double? _keyTotal() {
    final result = widget.scenario.result;
    return widget.scenario.type == 'rental'
        ? (result['first_month_total'] as num?)?.toDouble()
        : (result['monthly_repayment_estimate'] as num?)?.toDouble();
  }

  Future<void> _delete() async {
    setState(() => _deleting = true);
    try {
      await ref.read(calculatorsRepositoryProvider).deleteScenario(widget.scenario.id);
      ref.invalidate(savedScenariosProvider);
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scenario = widget.scenario;
    final keyTotal = _keyTotal();

    return Card(
      child: ListTile(
        leading: AppBadge(
          label: scenario.type == 'rental' ? 'Rental' : 'Purchase',
          tone: scenario.type == 'rental' ? BadgeTone.trust : BadgeTone.accent,
        ),
        title: Text(scenario.name?.isNotEmpty == true ? scenario.name! : 'Untitled scenario'),
        subtitle: Text(
          '${_dateFormat.format(DateTime.parse(scenario.createdAt))}'
          '${keyTotal != null ? ' · ${NprFormatter.format(keyTotal)}' : ''}',
        ),
        trailing: _deleting
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
      ),
    );
  }
}
