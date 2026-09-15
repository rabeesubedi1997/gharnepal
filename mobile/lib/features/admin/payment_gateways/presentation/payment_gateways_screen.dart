import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/error_state.dart';
import '../../../../widgets/skeleton.dart';
import '../application/payment_gateway_admin_providers.dart';
import '../data/models/admin_payment_gateway.dart';
import '../data/models/gateway_catalog_entry.dart';

/// Mirrors the website's admin Payment gateways page: every way a buyer can
/// pay for a listing boost — eSewa, Khalti, IME Pay, PayPal, manual bank
/// transfer, or the test sandbox. Add as many merchant accounts as needed;
/// enabled ones appear at checkout immediately.
class PaymentGatewaysScreen extends ConsumerWidget {
  const PaymentGatewaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(gatewayCatalogProvider);
    final configs = ref.watch(adminPaymentGatewaysProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment gateways')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AddGatewayForm(catalog: catalog.valueOrNull ?? const []),
          const SizedBox(height: 16),
          configs.when(
            loading: () => const Skeleton(height: 160, borderRadius: BorderRadius.all(Radius.circular(12))),
            error: (error, _) => ErrorState(
              message: 'Could not load payment gateways.',
              onRetry: () => ref.invalidate(adminPaymentGatewaysProvider),
            ),
            data: (items) => Column(
              children: [
                for (final config in items)
                  _GatewayCard(
                    config: config,
                    fields: catalog.valueOrNull?.firstWhere(
                      (c) => c.provider == config.provider,
                      orElse: () => GatewayCatalogEntry(provider: config.provider, label: config.provider, fields: const []),
                    ).fields ?? const [],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialFields extends StatelessWidget {
  const _CredentialFields({required this.fields, required this.controllers});

  final List<GatewayCredentialField> fields;
  final Map<String, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (final field in fields) ...[
          const SizedBox(height: 10),
          TextField(
            controller: controllers[field.key],
            obscureText: field.type == 'password',
            decoration: InputDecoration(labelText: field.label),
          ),
        ],
      ],
    );
  }
}

class _AddGatewayForm extends ConsumerStatefulWidget {
  const _AddGatewayForm({required this.catalog});

  final List<GatewayCatalogEntry> catalog;

  @override
  ConsumerState<_AddGatewayForm> createState() => _AddGatewayFormState();
}

class _AddGatewayFormState extends ConsumerState<_AddGatewayForm> {
  String? _provider;
  final _labelController = TextEditingController();
  final _instructionsController = TextEditingController();
  bool _isSandbox = true;
  Map<String, TextEditingController> _credentialControllers = {};
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _labelController.dispose();
    _instructionsController.dispose();
    for (final c in _credentialControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<GatewayCredentialField> get _fields =>
      widget.catalog.firstWhere((c) => c.provider == _provider, orElse: () => GatewayCatalogEntry(provider: '', label: '', fields: const [])).fields;

  void _selectProvider(String? provider) {
    for (final c in _credentialControllers.values) {
      c.dispose();
    }
    setState(() {
      _provider = provider;
      final fields = widget.catalog.firstWhere((c) => c.provider == provider, orElse: () => GatewayCatalogEntry(provider: '', label: '', fields: const [])).fields;
      _credentialControllers = {for (final f in fields) f.key: TextEditingController()};
    });
  }

  Future<void> _create() async {
    final provider = _provider;
    if (provider == null || _labelController.text.trim().isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(paymentGatewayAdminRepositoryProvider).create(
        provider: provider,
        label: _labelController.text.trim(),
        isSandbox: _isSandbox,
        instructions: provider == 'manual' ? _instructionsController.text.trim() : null,
        credentials: {
          for (final entry in _credentialControllers.entries)
            if (entry.value.text.trim().isNotEmpty) entry.key: entry.value.text.trim(),
        },
      );
      ref.invalidate(adminPaymentGatewaysProvider);
      _labelController.clear();
      _instructionsController.clear();
      _selectProvider(null);
      setState(() => _isSandbox = true);
    } catch (error) {
      final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
      if (mounted) setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add a payment method', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _provider,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Provider'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Choose a provider…')),
                for (final c in widget.catalog) DropdownMenuItem(value: c.provider, child: Text(c.label)),
              ],
              onChanged: _selectProvider,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Name for this account', hintText: 'e.g. eSewa — main account'),
            ),
            if (_provider != null && _provider != 'manual' && _provider != 'sandbox') ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text("Sandbox / test mode (uncheck once you're ready to take real payments)"),
                value: _isSandbox,
                onChanged: (v) => setState(() => _isSandbox = v ?? true),
              ),
            ],
            if (_provider == 'manual') ...[
              const SizedBox(height: 10),
              TextField(
                controller: _instructionsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Instructions shown to the buyer',
                  hintText: 'e.g. Transfer to Global IME Bank, account 01234567, then send the receipt on WhatsApp.',
                ),
              ),
            ],
            _CredentialFields(fields: _fields, controllers: _credentialControllers),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.danger600)),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                label: 'Add',
                expand: false,
                isLoading: _busy,
                onPressed: (_provider != null && _labelController.text.trim().isNotEmpty) ? _create : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GatewayCard extends ConsumerStatefulWidget {
  const _GatewayCard({required this.config, required this.fields});

  final AdminPaymentGateway config;
  final List<GatewayCredentialField> fields;

  @override
  ConsumerState<_GatewayCard> createState() => _GatewayCardState();
}

class _GatewayCardState extends ConsumerState<_GatewayCard> {
  bool _editing = false;
  late final _labelController = TextEditingController(text: widget.config.label);
  late final _instructionsController = TextEditingController(text: widget.config.instructions ?? '');
  Map<String, TextEditingController> _credentialControllers = {};
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _credentialControllers = {for (final f in widget.fields) f.key: TextEditingController()};
  }

  @override
  void dispose() {
    _labelController.dispose();
    _instructionsController.dispose();
    for (final c in _credentialControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _toggleEnabled(bool enabled) async {
    try {
      await ref.read(paymentGatewayAdminRepositoryProvider).update(widget.config.id, isEnabled: enabled);
      ref.invalidate(adminPaymentGatewaysProvider);
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException ? error.message : 'Could not update this gateway.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(paymentGatewayAdminRepositoryProvider).update(
        widget.config.id,
        label: _labelController.text.trim(),
        instructions: widget.config.provider == 'manual' ? _instructionsController.text.trim() : null,
        credentials: {
          for (final entry in _credentialControllers.entries)
            if (entry.value.text.trim().isNotEmpty) entry.key: entry.value.text.trim(),
        },
      );
      ref.invalidate(adminPaymentGatewaysProvider);
      if (mounted) setState(() => _editing = false);
    } catch (error) {
      final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
      if (mounted) setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this payment method?'),
        content: Text('This removes "${widget.config.label}" — buyers will no longer see it at checkout.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(paymentGatewayAdminRepositoryProvider).delete(widget.config.id);
      ref.invalidate(adminPaymentGatewaysProvider);
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException ? error.message : 'Could not delete this gateway.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(config.label, style: Theme.of(context).textTheme.titleSmall),
                      _Chip(label: config.provider),
                      if (config.isSandbox) _Chip(label: 'sandbox', color: AppColors.warning100, textColor: AppColors.warning600),
                    ],
                  ),
                ),
                Switch(value: config.isEnabled, onChanged: _toggleEnabled),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _editing = !_editing),
                  child: Text(_editing ? 'Cancel' : 'Edit'),
                ),
                IconButton(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger600),
                  tooltip: 'Delete',
                ),
              ],
            ),
            if (!_editing && config.provider != 'sandbox')
              Text(
                widget.fields.isEmpty
                    ? '—'
                    : widget.fields
                        .map((f) => '${f.label}: ${config.credentials[f.key]?.configured ?? false ? (f.type == 'text' ? (config.credentials[f.key]?.value ?? 'set') : 'set') : 'not set'}')
                        .join(' · '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
              ),
            if (_editing) ...[
              const Divider(),
              TextField(controller: _labelController, decoration: const InputDecoration(labelText: 'Name for this account')),
              if (config.provider == 'manual') ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _instructionsController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Instructions shown to the buyer'),
                ),
              ],
              if (widget.fields.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Leave a field blank to keep its current value.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                ),
                _CredentialFields(fields: widget.fields, controllers: _credentialControllers),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.danger600)),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: AppButton(label: 'Save', expand: false, isLoading: _busy, onPressed: _save),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.color, this.textColor});

  final String label;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? AppColors.stone200,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: textColor ?? AppColors.ink700)),
    );
  }
}
