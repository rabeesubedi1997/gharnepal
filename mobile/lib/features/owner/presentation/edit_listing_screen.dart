import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/error_state.dart';
import '../../listings/application/listings_providers.dart';
import '../../listings/data/models/listing_detail.dart';
import '../application/owner_providers.dart';

/// Mirrors frontend/src/pages/EditListing.tsx: only listing-level fields are
/// editable here — property fields (address/area/bedrooms) are fixed after
/// posting, edited (if ever) via the Property resource directly, not this
/// screen. Editing a published listing does NOT re-enter moderation; that
/// only happens through the Dashboard's explicit "Submit for review" action.
class EditListingScreen extends ConsumerWidget {
  const EditListingScreen({super.key, required this.listingId});

  final int listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listing = ref.watch(ownerListingProvider(listingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit listing')),
      body: listing.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: 'Could not load this listing.',
          onRetry: () => ref.invalidate(ownerListingProvider(listingId)),
        ),
        data: (data) => _EditListingForm(listing: data),
      ),
    );
  }
}

class _EditListingForm extends ConsumerStatefulWidget {
  const _EditListingForm({required this.listing});

  final ListingDetail listing;

  @override
  ConsumerState<_EditListingForm> createState() => _EditListingFormState();
}

class _EditListingFormState extends ConsumerState<_EditListingForm> {
  late final _titleController = TextEditingController(text: widget.listing.title);
  late final _descriptionController = TextEditingController(text: widget.listing.description ?? '');
  late final _priceController = TextEditingController(text: widget.listing.price.toStringAsFixed(0));
  late String? _pricePeriod = widget.listing.pricePeriod;
  late bool _negotiable = widget.listing.negotiable;
  DateTime? _availabilityDate;
  late final Set<int> _amenityIds = widget.listing.amenities.map((a) => a.id).toSet();
  bool _saving = false;

  static final _dateFormat = DateFormat('d MMM y');

  @override
  void initState() {
    super.initState();
    final raw = widget.listing.availabilityDate;
    _availabilityDate = raw != null ? DateTime.tryParse(raw) : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickAvailability() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _availabilityDate ?? now,
    );
    if (picked != null) setState(() => _availabilityDate = picked);
  }

  Future<void> _save() async {
    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid price.')));
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(ownerRepositoryProvider)
          .updateListing(
            widget.listing.id,
            price: price,
            pricePeriod: _pricePeriod,
            negotiable: _negotiable,
            availabilityDate: _availabilityDate,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            amenityIds: _amenityIds.toList(),
          );
      ref.invalidate(ownerListingProvider(widget.listing.id));
      ref.invalidate(myPropertiesProvider);
      ref.invalidate(listingDetailProvider(widget.listing.slug));
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing updated.')));
      }
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amenities = ref.watch(amenitiesProvider);
    final isRent = widget.listing.purpose == 'rent';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Property details (address, area, bedrooms) are fixed after posting — only the fields below can change.',
        ),
        const SizedBox(height: 16),
        TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Price (Rs)${isRent ? ' / month or total' : ''}'),
        ),
        if (isRent) ...[
          const SizedBox(height: 12),
          Text('Price period', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'monthly', label: Text('Monthly')),
              ButtonSegment(value: 'total', label: Text('Total')),
            ],
            selected: {_pricePeriod ?? 'monthly'},
            onSelectionChanged: (value) => setState(() => _pricePeriod = value.first),
          ),
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Negotiable'),
          value: _negotiable,
          onChanged: (value) => setState(() => _negotiable = value),
        ),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: _pickAvailability,
          icon: const Icon(Icons.event),
          label: Text(
            _availabilityDate == null
                ? 'Set availability date (optional)'
                : 'Available from ${_dateFormat.format(_availabilityDate!)}',
          ),
        ),
        const SizedBox(height: 16),
        Text('Amenities', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        amenities.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 18, color: AppColors.danger600),
                const SizedBox(width: 8),
                const Expanded(child: Text('Could not load amenities.')),
                TextButton(onPressed: () => ref.invalidate(amenitiesProvider), child: const Text('Retry')),
              ],
            ),
          ),
          data: (items) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((amenity) {
              final selected = _amenityIds.contains(amenity.id);
              return FilterChip(
                label: Text(amenity.name),
                selected: selected,
                onSelected: (value) => setState(() {
                  if (value) {
                    _amenityIds.add(amenity.id);
                  } else {
                    _amenityIds.remove(amenity.id);
                  }
                }),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        AppButton(label: 'Save changes', isLoading: _saving, onPressed: _save),
      ],
    );
  }
}
