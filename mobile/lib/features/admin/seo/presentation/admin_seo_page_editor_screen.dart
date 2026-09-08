import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/error_state.dart';
import '../application/admin_seo_providers.dart';
import '../data/models/seo_competitor_scan.dart';
import '../data/models/seo_page_detail.dart';

/// SEO override editor for one synthetic `page_key`. Shows the live
/// "effective" meta as read-only reference, an editable override form below
/// it, a raw structured-data viewer, and a competitor-scan workbench.
class AdminSeoPageEditorScreen extends ConsumerStatefulWidget {
  const AdminSeoPageEditorScreen({super.key, required this.pageKey});

  final String pageKey;

  @override
  ConsumerState<AdminSeoPageEditorScreen> createState() => _AdminSeoPageEditorScreenState();
}

class _AdminSeoPageEditorScreenState extends ConsumerState<AdminSeoPageEditorScreen> {
  final _metaTitleController = TextEditingController();
  final _metaDescriptionController = TextEditingController();
  final _metaKeywordsController = TextEditingController();
  final _ogImageUrlController = TextEditingController();
  final _canonicalPathController = TextEditingController();
  final _scanUrlController = TextEditingController();

  bool _robotsIndex = true;
  bool _robotsFollow = true;
  String _status = 'draft';

  SeoEffective? _effective;
  List<SeoCompetitorScan> _scans = [];
  bool _hasOverride = false;
  bool _initialized = false;
  bool _saving = false;
  bool _resetting = false;
  bool _scanning = false;

  @override
  void dispose() {
    _metaTitleController.dispose();
    _metaDescriptionController.dispose();
    _metaKeywordsController.dispose();
    _ogImageUrlController.dispose();
    _canonicalPathController.dispose();
    _scanUrlController.dispose();
    super.dispose();
  }

  void _populate(SeoPageDetail detail) {
    _effective = detail.effective;
    _scans = detail.scans;
    _hasOverride = detail.effective.hasOverride;
    final override = detail.override;
    _metaTitleController.text = override?.metaTitle ?? '';
    _metaDescriptionController.text = override?.metaDescription ?? '';
    _metaKeywordsController.text = override?.metaKeywords ?? '';
    _ogImageUrlController.text = override?.ogImageUrl ?? '';
    _canonicalPathController.text = override?.canonicalPath ?? '';
    _robotsIndex = override?.robotsIndex ?? true;
    _robotsFollow = override?.robotsFollow ?? true;
    _status = override?.status ?? 'draft';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final result = await ref.read(adminSeoRepositoryProvider).updatePage(
        widget.pageKey,
        metaTitle: _metaTitleController.text.trim().isEmpty ? null : _metaTitleController.text.trim(),
        metaDescription: _metaDescriptionController.text.trim().isEmpty ? null : _metaDescriptionController.text.trim(),
        metaKeywords: _metaKeywordsController.text.trim().isEmpty ? null : _metaKeywordsController.text.trim(),
        ogImageUrl: _ogImageUrlController.text.trim().isEmpty ? null : _ogImageUrlController.text.trim(),
        canonicalPath: _canonicalPathController.text.trim().isEmpty ? null : _canonicalPathController.text.trim(),
        robotsIndex: _robotsIndex,
        robotsFollow: _robotsFollow,
        status: _status,
      );
      // The PUT response omits `scans` — keep the existing scans list as-is.
      setState(() {
        _effective = result.effective;
        _hasOverride = result.effective.hasOverride;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved.')));
      }
    } catch (error) {
      if (mounted) _showError(error, 'Could not save this page.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reset() async {
    setState(() => _resetting = true);
    try {
      await ref.read(adminSeoRepositoryProvider).resetPage(widget.pageKey);
      setState(() => _initialized = false);
      ref.invalidate(adminSeoPageProvider(widget.pageKey));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset to auto-generated default.')));
      }
    } catch (error) {
      if (mounted) _showError(error, 'Could not reset this page.');
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  Future<void> _scan() async {
    final url = _scanUrlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _scanning = true);
    try {
      final scan = await ref.read(adminSeoRepositoryProvider).scan(widget.pageKey, url);
      setState(() {
        _scans = [scan, ..._scans];
        _scanUrlController.clear();
      });
    } catch (error) {
      if (mounted) _showError(error, 'Could not scan that URL.');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _discardScan(SeoCompetitorScan scan) async {
    try {
      await ref.read(adminSeoRepositoryProvider).deleteScan(scan.id);
      setState(() => _scans = _scans.where((s) => s.id != scan.id).toList());
    } catch (error) {
      if (mounted) _showError(error, 'Could not discard this scan.');
    }
  }

  void _showError(Object error, String fallback) {
    final message = error is ApiException ? error.message : fallback;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(adminSeoPageProvider(widget.pageKey));

    return Scaffold(
      appBar: AppBar(title: Text(widget.pageKey)),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: 'Could not load this page.',
          onRetry: () => ref.invalidate(adminSeoPageProvider(widget.pageKey)),
        ),
        data: (data) {
          if (!_initialized) {
            _populate(data);
            _initialized = true;
          }
          return _buildBody(context);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final effective = _effective!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _EffectiveReference(effective: effective),
        const SizedBox(height: 20),
        Text('Override', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(controller: _metaTitleController, maxLength: 255, decoration: const InputDecoration(labelText: 'Meta title')),
        TextField(
          controller: _metaDescriptionController,
          maxLength: 320,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Meta description'),
        ),
        TextField(
          controller: _metaKeywordsController,
          maxLength: 500,
          decoration: const InputDecoration(labelText: 'Meta keywords'),
        ),
        TextField(controller: _ogImageUrlController, maxLength: 2048, decoration: const InputDecoration(labelText: 'OG image URL')),
        TextField(
          controller: _canonicalPathController,
          maxLength: 255,
          decoration: const InputDecoration(labelText: 'Canonical path', hintText: 'Must start with /'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Robots: index'),
          value: _robotsIndex,
          onChanged: (value) => setState(() => _robotsIndex = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Robots: follow'),
          value: _robotsFollow,
          onChanged: (value) => setState(() => _robotsFollow = value),
        ),
        Row(
          children: [
            const Text('Status:'),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _status,
                isDense: true,
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'published', child: Text('Published')),
                ],
                onChanged: (value) => setState(() => _status = value ?? _status),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppButton(label: 'Save', isLoading: _saving, onPressed: _save),
        const SizedBox(height: 10),
        AppButton(
          label: 'Reset to auto-generated default',
          variant: AppButtonVariant.outlined,
          isLoading: _resetting,
          onPressed: _hasOverride ? _reset : null,
        ),
        const SizedBox(height: 24),
        _StructuredDataViewer(structuredData: effective.structuredData),
        const SizedBox(height: 24),
        Text('Competitor scans', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _scanUrlController,
                decoration: const InputDecoration(labelText: 'Competitor URL', isDense: true),
              ),
            ),
            const SizedBox(width: 8),
            AppButton(label: 'Scan', expand: false, isLoading: _scanning, onPressed: _scan),
          ],
        ),
        const SizedBox(height: 12),
        if (_scans.isEmpty)
          Text('No pending scans.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700))
        else
          for (final scan in _scans)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ScanCard(
                scan: scan,
                onUseTitle: scan.scannedTitle == null
                    ? null
                    : () => setState(() => _metaTitleController.text = scan.scannedTitle!),
                onUseDescription: scan.scannedMetaDescription == null
                    ? null
                    : () => setState(() => _metaDescriptionController.text = scan.scannedMetaDescription!),
                onUseImage: scan.scannedOgImage == null
                    ? null
                    : () => setState(() => _ogImageUrlController.text = scan.scannedOgImage!),
                onUseKeywords: scan.scannedKeywords.isEmpty
                    ? null
                    : () => setState(() => _metaKeywordsController.text = scan.keywordsAsCsv),
                onDiscard: () => _discardScan(scan),
              ),
            ),
      ],
    );
  }
}

class _EffectiveReference extends StatelessWidget {
  const _EffectiveReference({required this.effective});

  final SeoEffective effective;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.stone100, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live now', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.ink700)),
          const SizedBox(height: 6),
          Text(effective.title, style: Theme.of(context).textTheme.titleSmall),
          if (effective.description != null) Text(effective.description!),
          const SizedBox(height: 4),
          if (effective.canonicalUrl != null)
            Text('Canonical: ${effective.canonicalUrl}', style: Theme.of(context).textTheme.bodySmall),
          if (effective.ogImage != null)
            Text('OG image: ${effective.ogImage}', style: Theme.of(context).textTheme.bodySmall),
          Text(
            'Robots: ${effective.robots.index ? 'index' : 'noindex'}, ${effective.robots.follow ? 'follow' : 'nofollow'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StructuredDataViewer extends StatelessWidget {
  const _StructuredDataViewer({required this.structuredData});

  final dynamic structuredData;

  @override
  Widget build(BuildContext context) {
    if (structuredData == null) {
      return const SizedBox.shrink();
    }
    String pretty;
    try {
      pretty = const JsonEncoder.withIndent('  ').convert(structuredData);
    } catch (_) {
      pretty = structuredData.toString();
    }
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('Structured data (JSON-LD)'),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.stone100, borderRadius: BorderRadius.circular(8)),
          child: SelectableText(pretty, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
      ],
    );
  }
}

class _ScanCard extends StatelessWidget {
  const _ScanCard({
    required this.scan,
    required this.onUseTitle,
    required this.onUseDescription,
    required this.onUseImage,
    required this.onUseKeywords,
    required this.onDiscard,
  });

  final SeoCompetitorScan scan;
  final VoidCallback? onUseTitle;
  final VoidCallback? onUseDescription;
  final VoidCallback? onUseImage;
  final VoidCallback? onUseKeywords;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    scan.competitorUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(onPressed: onDiscard, icon: const Icon(Icons.close), visualDensity: VisualDensity.compact),
              ],
            ),
            if (scan.scannedTitle != null) Text('Title: ${scan.scannedTitle}', maxLines: 2, overflow: TextOverflow.ellipsis),
            if (scan.scannedMetaDescription != null)
              Text('Description: ${scan.scannedMetaDescription}', maxLines: 2, overflow: TextOverflow.ellipsis),
            Text('${scan.wordCount} words', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton(onPressed: onUseTitle, child: const Text('Use title')),
                OutlinedButton(onPressed: onUseDescription, child: const Text('Use description')),
                OutlinedButton(onPressed: onUseImage, child: const Text('Use image')),
                OutlinedButton(onPressed: onUseKeywords, child: const Text('Use as keywords')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
