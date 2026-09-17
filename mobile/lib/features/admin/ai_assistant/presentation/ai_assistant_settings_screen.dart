import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/error_state.dart';
import '../../../../widgets/skeleton.dart';
import '../application/ai_provider_admin_providers.dart';
import '../data/models/admin_ai_provider.dart';
import '../data/models/ai_provider_catalog_entry.dart';

/// Mirrors the website's admin AI assistant page: the property-search
/// assistant runs on a free, built-in search engine by default, and an
/// admin can add any number of real AI agents here — Claude, OpenAI,
/// Gemini, or a "Custom" OpenAI-compatible agent for anything else — but
/// only one can be Active at a time.
class AiAssistantSettingsScreen extends ConsumerWidget {
  const AiAssistantSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(aiProviderCatalogProvider);
    final configs = ref.watch(adminAiProvidersProvider);
    final currentlyActive = configs.valueOrNull?.where((c) => c.isEnabled).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('AI assistant')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'The property-search assistant runs on a free, built-in search engine by default — no API key needed, no cost. '
            'Add an AI agent below and mark it Active to upgrade to a genuinely open-ended conversation instead. '
            'Only one agent can be active at a time; enabling one switches any other off (you\'ll be asked to confirm first).',
            style: TextStyle(color: AppColors.ink700, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _AddAgentForm(catalog: catalog.valueOrNull ?? const []),
          const SizedBox(height: 16),
          configs.when(
            loading: () => const Skeleton(height: 160, borderRadius: BorderRadius.all(Radius.circular(12))),
            error: (error, _) =>
                ErrorState(message: 'Could not load AI agents.', onRetry: () => ref.invalidate(adminAiProvidersProvider)),
            data: (items) => Column(
              children: [
                for (final config in items)
                  _AgentCard(
                    config: config,
                    fields: catalog.valueOrNull
                            ?.firstWhere(
                              (c) => c.provider == config.provider,
                              orElse: () => AiProviderCatalogEntry(provider: config.provider, label: config.provider, fields: const []),
                            )
                            .fields ??
                        const [],
                    otherEnabled: !config.isEnabled && currentlyActive != null && currentlyActive.id != config.id ? currentlyActive : null,
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

  final List<AiProviderCredentialField> fields;
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

class _AddAgentForm extends ConsumerStatefulWidget {
  const _AddAgentForm({required this.catalog});

  final List<AiProviderCatalogEntry> catalog;

  @override
  ConsumerState<_AddAgentForm> createState() => _AddAgentFormState();
}

class _AddAgentFormState extends ConsumerState<_AddAgentForm> {
  String? _provider;
  final _labelController = TextEditingController();
  Map<String, TextEditingController> _credentialControllers = {};
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _labelController.dispose();
    for (final c in _credentialControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<AiProviderCredentialField> get _fields => widget.catalog
      .firstWhere((c) => c.provider == _provider, orElse: () => AiProviderCatalogEntry(provider: '', label: '', fields: const []))
      .fields;

  void _selectProvider(String? provider) {
    for (final c in _credentialControllers.values) {
      c.dispose();
    }
    setState(() {
      _provider = provider;
      final fields = widget.catalog
          .firstWhere((c) => c.provider == provider, orElse: () => AiProviderCatalogEntry(provider: '', label: '', fields: const []))
          .fields;
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
      await ref.read(aiProviderAdminRepositoryProvider).create(
        provider: provider,
        label: _labelController.text.trim(),
        credentials: {
          for (final entry in _credentialControllers.entries)
            if (entry.value.text.trim().isNotEmpty) entry.key: entry.value.text.trim(),
        },
      );
      ref.invalidate(adminAiProvidersProvider);
      _labelController.clear();
      _selectProvider(null);
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
            Text('Add an AI agent', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'Add as many as you like — including several of the same kind. Only one can be Active at a time.',
              style: TextStyle(color: AppColors.ink700, fontSize: 12),
            ),
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
              decoration: const InputDecoration(labelText: 'Name for this agent', hintText: 'e.g. Claude — production key'),
            ),
            if (_provider == 'custom') ...[
              const SizedBox(height: 8),
              const Text(
                'Any AI agent whose API speaks the OpenAI Chat Completions format works here — Groq, Together, DeepSeek, OpenRouter, '
                'a local Ollama instance, etc. Point it at that vendor\'s base URL, drop in the API key and model name, and it works '
                'immediately once saved and switched Active — no code changes needed.',
                style: TextStyle(color: AppColors.ink700, fontSize: 12),
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

class _AgentCard extends ConsumerStatefulWidget {
  const _AgentCard({required this.config, required this.fields, this.otherEnabled});

  final AdminAiProvider config;
  final List<AiProviderCredentialField> fields;
  /// The one other agent currently Active, if any — enabling this one will switch it off.
  final AdminAiProvider? otherEnabled;

  @override
  ConsumerState<_AgentCard> createState() => _AgentCardState();
}

class _AgentCardState extends ConsumerState<_AgentCard> {
  bool _editing = false;
  late final _labelController = TextEditingController(text: widget.config.label);
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
    for (final c in _credentialControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _toggleEnabled(bool enabled) async {
    if (enabled && widget.otherEnabled != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Switch active AI agent?'),
          content: Text(
            'Only one AI agent can be active at a time. Enabling "${widget.config.label}" will automatically switch off '
            '"${widget.otherEnabled!.label}" — its credentials stay saved, just inactive.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Continue')),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      final result = await ref.read(aiProviderAdminRepositoryProvider).update(widget.config.id, isEnabled: enabled);
      ref.invalidate(adminAiProvidersProvider);
      if (!mounted) return;

      if (result.disabledOthers.isNotEmpty) {
        final names = result.disabledOthers.map((d) => d.label).join('", "');
        final verb = result.disabledOthers.length > 1 ? 'were' : 'was';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${widget.config.label}" is now active. "$names" $verb switched off automatically.')),
        );
      } else if (enabled) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${widget.config.label}" is now active.')));
      }
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException ? error.message : 'Could not update this agent.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(aiProviderAdminRepositoryProvider).update(
        widget.config.id,
        label: _labelController.text.trim(),
        credentials: {
          for (final entry in _credentialControllers.entries)
            if (entry.value.text.trim().isNotEmpty) entry.key: entry.value.text.trim(),
        },
      );
      ref.invalidate(adminAiProvidersProvider);
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
        title: const Text('Remove this AI agent?'),
        content: Text('This deletes "${widget.config.label}"\'s saved credentials — it can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(aiProviderAdminRepositoryProvider).delete(widget.config.id);
      ref.invalidate(adminAiProvidersProvider);
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException ? error.message : 'Could not remove this agent.';
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
                      if (config.isEnabled) _Chip(label: 'active', color: AppColors.success100, textColor: AppColors.success600),
                    ],
                  ),
                ),
                Switch(value: config.isEnabled, onChanged: _toggleEnabled),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => setState(() => _editing = !_editing), child: Text(_editing ? 'Cancel' : 'Edit')),
                IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline, color: AppColors.danger600), tooltip: 'Remove'),
              ],
            ),
            if (!_editing)
              Text(
                widget.fields.isEmpty
                    ? '—'
                    : widget.fields
                        .map(
                          (f) =>
                              '${f.label}: ${config.credentials[f.key]?.configured ?? false ? (f.type == 'text' ? (config.credentials[f.key]?.value ?? 'set') : 'set') : 'not set'}',
                        )
                        .join(' · '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
              ),
            if (_editing) ...[
              const Divider(),
              TextField(controller: _labelController, decoration: const InputDecoration(labelText: 'Name for this agent')),
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
      decoration: BoxDecoration(color: color ?? AppColors.stone200, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 11, color: textColor ?? AppColors.ink700)),
    );
  }
}
