import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../widgets/app_button.dart';
import '../application/property_requests_providers.dart';

/// Mirrors the "Post a request" form on frontend/src/pages/PropertyRequests/index.tsx.
class CreatePropertyRequestSheet extends ConsumerStatefulWidget {
  const CreatePropertyRequestSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CreatePropertyRequestSheet(),
    );
  }

  @override
  ConsumerState<CreatePropertyRequestSheet> createState() => _CreatePropertyRequestSheetState();
}

class _CreatePropertyRequestSheetState extends ConsumerState<CreatePropertyRequestSheet> {
  String _purpose = 'rent';
  String? _propertyType;
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  int? _bedroomsMin;
  final _notesController = TextEditingController();
  bool _submitting = false;

  static const _propertyTypes = ['room', 'apartment', 'house', 'land', 'commercial'];

  @override
  void dispose() {
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(propertyRequestsRepositoryProvider)
          .create(
            purpose: _purpose,
            propertyType: _propertyType,
            budgetMin: int.tryParse(_budgetMinController.text),
            budgetMax: int.tryParse(_budgetMaxController.text),
            bedroomsMin: _bedroomsMin,
            notes: _notesController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Post what you\'re looking for', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'rent', label: Text('Rent')),
                  ButtonSegment(value: 'sale', label: Text('Buy')),
                ],
                selected: {_purpose},
                onSelectionChanged: (value) => setState(() => _purpose = value.first),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _propertyType,
                decoration: const InputDecoration(labelText: 'Property type (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any type')),
                  ..._propertyTypes.map((t) => DropdownMenuItem(value: t, child: Text(t[0].toUpperCase() + t.substring(1)))),
                ],
                onChanged: (value) => setState(() => _propertyType = value),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _budgetMinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Min budget (Rs)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _budgetMaxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max budget (Rs)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                initialValue: _bedroomsMin,
                decoration: const InputDecoration(labelText: 'Minimum bedrooms (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any')),
                  ...List.generate(5, (i) => i + 1).map((n) => DropdownMenuItem(value: n, child: Text('$n+'))),
                ],
                onChanged: (value) => setState(() => _bedroomsMin = value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes (optional)', alignLabelWithHint: true),
              ),
              const SizedBox(height: 20),
              AppButton(label: 'Post request', isLoading: _submitting, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
