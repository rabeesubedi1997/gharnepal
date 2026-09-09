import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/formatters/area_unit_converter.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_button.dart';
import '../../listings/application/listings_providers.dart';
import '../../listings/data/models/media_item.dart';
import '../../locations/application/locations_providers.dart';
import '../../matching/presentation/work_location_picker.dart';
import '../application/owner_providers.dart';

/// Mirrors frontend/src/pages/PostPropertyWizard/index.tsx — but the real
/// state machine lives on the backend, not in this widget: each step below
/// fires its own, separate API call the moment the user continues (create
/// Property -> [land profile] -> media -> create Listing -> submit), so a
/// user who abandons the wizard midway already has a resumable `draft`
/// listing sitting on their Dashboard, not lost work. There is no
/// "autosave partial progress" endpoint to call beyond that.
class PostPropertyWizardScreen extends ConsumerStatefulWidget {
  const PostPropertyWizardScreen({super.key});

  @override
  ConsumerState<PostPropertyWizardScreen> createState() => _PostPropertyWizardScreenState();
}

const _propertyTypes = ['room', 'apartment', 'house', 'land', 'commercial'];
const _residentialTypes = ['room', 'apartment', 'house'];

class _PostPropertyWizardScreenState extends ConsumerState<PostPropertyWizardScreen> {
  int _stepIndex = 0;
  bool _busy = false;

  // --- Step 0: type + location ---
  String? _propertyType;
  int? _provinceId;
  int? _districtId;
  int? _municipalityId;
  int? _wardId;
  int? _neighborhoodId;
  final _streetController = TextEditingController();
  final _landmarkController = TextEditingController();
  double? _lat;
  double? _lng;

  // --- Step 1: basics ---
  final _areaValueController = TextEditingController();
  String? _areaUnit;
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _floorsController = TextEditingController();
  final _yearBuiltController = TextEditingController();
  final _parkingSpacesController = TextEditingController();
  String? _parkingType;
  String? _isFurnished;

  int? _propertyId;

  // --- Step 2: land profile (land only) ---
  final _kittaController = TextEditingController();
  String _lalpurjaAvailable = 'unknown';
  bool _roadAccess = false;
  final _roadWidthController = TextEditingController();
  String _roadType = 'none';
  String _waterAccess = 'unknown';
  bool _electricityAccess = false;
  String _drainageAccess = 'unknown';
  String _landClassification = 'residential';
  String _floodRisk = 'unknown';
  String _landslideRisk = 'unknown';
  final _landNotesController = TextEditingController();

  // --- Step 3: media ---
  final List<MediaItem> _media = [];

  // --- Step 4: pricing ---
  String _purpose = 'sale';
  final _priceController = TextEditingController();
  String _pricePeriod = 'monthly';
  bool _negotiable = false;
  DateTime? _availabilityDate;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<int> _amenityIds = {};
  String? _titleError;

  int? _listingId;

  static final _dateFormat = DateFormat('d MMM y');

  bool get _isLand => _propertyType == 'land';

  List<String> get _activeSteps => ['location', 'basics', if (_isLand) 'land', 'media', 'pricing', 'review'];

  @override
  void dispose() {
    _streetController.dispose();
    _landmarkController.dispose();
    _areaValueController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _floorsController.dispose();
    _yearBuiltController.dispose();
    _parkingSpacesController.dispose();
    _kittaController.dispose();
    _roadWidthController.dispose();
    _landNotesController.dispose();
    _priceController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _error(Object error) {
    final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _back() async {
    if (_stepIndex == 0) {
      context.pop();
      return;
    }
    setState(() => _stepIndex -= 1);
  }

  Future<void> _next() async {
    final step = _activeSteps[_stepIndex];
    switch (step) {
      case 'location':
        await _submitLocationStep();
      case 'basics':
        await _submitBasicsStep();
      case 'land':
        await _submitLandStep();
      case 'media':
        _submitMediaStep();
      case 'pricing':
        await _submitPricingStep();
    }
  }

  Future<void> _submitLocationStep() async {
    if (_propertyType == null || _provinceId == null || _districtId == null || _municipalityId == null || _wardId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose a property type and full address.')));
      return;
    }
    setState(() => _stepIndex += 1);
  }

  Future<void> _submitBasicsStep() async {
    final areaValue = double.tryParse(_areaValueController.text.trim());
    if (areaValue == null || areaValue <= 0 || _areaUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid area and unit.')));
      return;
    }
    final needsRoomCounts = _residentialTypes.contains(_propertyType);
    final bedrooms = int.tryParse(_bedroomsController.text.trim());
    final bathrooms = int.tryParse(_bathroomsController.text.trim());
    if (needsRoomCounts && (bedrooms == null || bathrooms == null)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter bedrooms and bathrooms.')));
      return;
    }

    setState(() => _busy = true);
    try {
      final property = await ref
          .read(ownerRepositoryProvider)
          .createProperty(
            propertyType: _propertyType!,
            areaValue: areaValue,
            areaUnit: _areaUnit!,
            bedrooms: needsRoomCounts ? bedrooms : null,
            bathrooms: needsRoomCounts ? bathrooms : null,
            floors: int.tryParse(_floorsController.text.trim()),
            yearBuilt: int.tryParse(_yearBuiltController.text.trim()),
            parkingSpaces: int.tryParse(_parkingSpacesController.text.trim()),
            parkingType: _parkingType,
            isFurnished: _isFurnished,
            provinceId: _provinceId!,
            districtId: _districtId!,
            municipalityId: _municipalityId!,
            wardId: _wardId!,
            neighborhoodId: _neighborhoodId,
            streetAddress: _streetController.text.trim(),
            landmark: _landmarkController.text.trim(),
            lat: _lat,
            lng: _lng,
          );
      if (!mounted) return;
      setState(() {
        _propertyId = property.id;
        _stepIndex += 1;
      });
    } catch (error) {
      if (mounted) _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitLandStep() async {
    setState(() => _busy = true);
    try {
      await ref.read(ownerRepositoryProvider).saveLandProfile(_propertyId!, {
        if (_kittaController.text.trim().isNotEmpty) 'kitta_number': _kittaController.text.trim(),
        'lalpurja_available': _lalpurjaAvailable,
        'road_access': _roadAccess,
        if (_roadWidthController.text.trim().isNotEmpty)
          'road_width_meters': double.tryParse(_roadWidthController.text.trim()),
        'road_type': _roadType,
        'water_access': _waterAccess,
        'electricity_access': _electricityAccess,
        'drainage_access': _drainageAccess,
        'land_classification': _landClassification,
        'flood_risk': _floodRisk,
        'landslide_risk': _landslideRisk,
        if (_landNotesController.text.trim().isNotEmpty) 'nearby_development_notes': _landNotesController.text.trim(),
      });
      if (!mounted) return;
      setState(() => _stepIndex += 1);
    } catch (error) {
      if (mounted) _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submitMediaStep() {
    if (_media.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one photo.')));
      return;
    }
    setState(() => _stepIndex += 1);
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty || !mounted) return;

    setState(() => _busy = true);
    for (final photo in picked) {
      try {
        final media = await ref.read(ownerRepositoryProvider).uploadMedia(_propertyId!, photo.path);
        if (mounted) setState(() => _media.add(media));
      } catch (error) {
        if (mounted) _error(error);
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _deletePhoto(MediaItem media) async {
    setState(() => _busy = true);
    try {
      await ref.read(ownerRepositoryProvider).deleteMedia(_propertyId!, media.id);
      if (mounted) setState(() => _media.removeWhere((m) => m.id == media.id));
    } catch (error) {
      if (mounted) _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitPricingStep() async {
    final price = double.tryParse(_priceController.text.trim());
    final title = _titleController.text.trim();
    final titleError = title.length < 5 ? 'Give your listing a descriptive title' : null;
    setState(() => _titleError = titleError);
    if (price == null || price <= 0 || titleError != null) {
      if (price == null || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid price.')));
      }
      return;
    }

    setState(() => _busy = true);
    try {
      final listing = await ref
          .read(ownerRepositoryProvider)
          .createListing(
            _propertyId!,
            purpose: _purpose,
            price: price,
            pricePeriod: _purpose == 'rent' ? _pricePeriod : null,
            negotiable: _negotiable,
            availabilityDate: _availabilityDate,
            title: title,
            description: _descriptionController.text.trim(),
            amenityIds: _amenityIds.toList(),
          );
      if (!mounted) return;
      setState(() {
        _listingId = listing.id;
        _stepIndex += 1;
      });
    } catch (error) {
      if (mounted) _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish({required bool submitForReview}) async {
    setState(() => _busy = true);
    try {
      if (submitForReview) {
        await ref.read(ownerRepositoryProvider).transitionListing(_listingId!, 'submit');
      }
      ref.invalidate(myPropertiesProvider);
      if (mounted) {
        context.go('/dashboard');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(submitForReview ? 'Listing submitted for review.' : 'Saved as draft on your Dashboard.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _activeSteps[_stepIndex];
    final isReview = step == 'review';

    return Scaffold(
      appBar: AppBar(title: const Text('Post a property')),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_stepIndex + 1) / _activeSteps.length),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: switch (step) {
                'location' => _buildLocationStep(),
                'basics' => _buildBasicsStep(),
                'land' => _buildLandStep(),
                'media' => _buildMediaStep(),
                'pricing' => _buildPricingStep(),
                _ => _buildReviewStep(),
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isReview
                  ? Column(
                      children: [
                        AppButton(
                          label: 'Submit for review',
                          isLoading: _busy,
                          onPressed: () => _finish(submitForReview: true),
                        ),
                        const SizedBox(height: 10),
                        AppButton(
                          label: 'Save as draft',
                          variant: AppButtonVariant.outlined,
                          isLoading: _busy,
                          onPressed: () => _finish(submitForReview: false),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: AppButton(label: 'Back', variant: AppButtonVariant.outlined, onPressed: _back),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: AppButton(label: 'Continue', isLoading: _busy, onPressed: _next)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step builders ---

  Widget _buildLocationStep() {
    final provinces = ref.watch(provincesProvider);
    final districts = _provinceId == null ? null : ref.watch(districtsProvider(_provinceId!));
    final municipalities = _districtId == null ? null : ref.watch(municipalitiesForDistrictProvider(_districtId!));
    final wards = _municipalityId == null ? null : ref.watch(wardsProvider(_municipalityId!));
    final neighborhoods = _wardId == null ? null : ref.watch(neighborhoodsProvider(_wardId!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Property type', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _propertyType,
          hint: const Text('Select type'),
          items: _propertyTypes
              .map((type) => DropdownMenuItem(value: type, child: Text(_titleCase(type))))
              .toList(),
          onChanged: (value) => setState(() => _propertyType = value),
        ),
        const SizedBox(height: 16),
        Text('Location', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        provinces.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => _inlineLoadError(
            'Could not load provinces.',
            () => ref.invalidate(provincesProvider),
          ),
          data: (items) => DropdownButtonFormField<int>(
            initialValue: _provinceId,
            decoration: const InputDecoration(labelText: 'Province'),
            items: items.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
            onChanged: (value) => setState(() {
              _provinceId = value;
              _districtId = null;
              _municipalityId = null;
              _wardId = null;
              _neighborhoodId = null;
            }),
          ),
        ),
        const SizedBox(height: 12),
        if (districts != null)
          districts.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => _inlineLoadError(
              'Could not load districts.',
              () => ref.invalidate(districtsProvider(_provinceId!)),
            ),
            data: (items) => DropdownButtonFormField<int>(
              initialValue: _districtId,
              decoration: const InputDecoration(labelText: 'District'),
              items: items.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
              onChanged: (value) => setState(() {
                _districtId = value;
                _municipalityId = null;
                _wardId = null;
                _neighborhoodId = null;
              }),
            ),
          ),
        const SizedBox(height: 12),
        if (municipalities != null)
          municipalities.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => _inlineLoadError(
              'Could not load municipalities.',
              () => ref.invalidate(municipalitiesForDistrictProvider(_districtId!)),
            ),
            data: (items) => DropdownButtonFormField<int>(
              initialValue: _municipalityId,
              decoration: const InputDecoration(labelText: 'Municipality'),
              items: items.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
              onChanged: (value) => setState(() {
                _municipalityId = value;
                _wardId = null;
                _neighborhoodId = null;
              }),
            ),
          ),
        const SizedBox(height: 12),
        if (wards != null)
          wards.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => _inlineLoadError(
              'Could not load wards.',
              () => ref.invalidate(wardsProvider(_municipalityId!)),
            ),
            data: (items) => DropdownButtonFormField<int>(
              initialValue: _wardId,
              decoration: const InputDecoration(labelText: 'Ward'),
              items: items.map((w) => DropdownMenuItem(value: w.id, child: Text(w.label))).toList(),
              onChanged: (value) => setState(() {
                _wardId = value;
                _neighborhoodId = null;
              }),
            ),
          ),
        const SizedBox(height: 12),
        if (neighborhoods != null)
          neighborhoods.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => _inlineLoadError(
              'Could not load neighborhoods.',
              () => ref.invalidate(neighborhoodsProvider(_wardId!)),
            ),
            data: (items) => DropdownButtonFormField<int?>(
              initialValue: _neighborhoodId,
              decoration: const InputDecoration(labelText: 'Neighborhood (optional)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...items.map((n) => DropdownMenuItem(value: n.id, child: Text(n.name))),
              ],
              onChanged: (value) => setState(() => _neighborhoodId = value),
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _streetController,
          decoration: const InputDecoration(labelText: 'Street address (optional)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _landmarkController,
          decoration: const InputDecoration(labelText: 'Nearby landmark (optional)'),
        ),
        const SizedBox(height: 16),
        Text('Pin location on map (optional)', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        const Text('Tap the map to drop a pin at the property\'s exact location.'),
        const SizedBox(height: 8),
        WorkLocationPicker(
          initialLat: _lat,
          initialLng: _lng,
          onChanged: (lat, lng) => setState(() {
            _lat = lat;
            _lng = lng;
          }),
        ),
      ],
    );
  }

  Widget _buildBasicsStep() {
    final needsRoomCounts = _residentialTypes.contains(_propertyType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Area', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _areaValueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Area value'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _areaUnit,
                hint: const Text('Unit'),
                items: AreaUnitConverter.units
                    .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                    .toList(),
                onChanged: (value) => setState(() => _areaUnit = value),
              ),
            ),
          ],
        ),
        if (needsRoomCounts) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bedroomsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Bedrooms'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _bathroomsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Bathrooms'),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _floorsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Floors (optional)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _yearBuiltController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Year built (optional)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _parkingSpacesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Parking spaces (optional)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: _parkingType,
                decoration: const InputDecoration(labelText: 'Parking type'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('—')),
                  DropdownMenuItem(value: 'car', child: Text('Car')),
                  DropdownMenuItem(value: 'bike', child: Text('Bike')),
                  DropdownMenuItem(value: 'both', child: Text('Both')),
                ],
                onChanged: (value) => setState(() => _parkingType = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String?>(
          initialValue: _isFurnished,
          decoration: const InputDecoration(labelText: 'Furnishing (optional)'),
          items: const [
            DropdownMenuItem(value: null, child: Text('—')),
            DropdownMenuItem(value: 'unfurnished', child: Text('Unfurnished')),
            DropdownMenuItem(value: 'semi', child: Text('Semi-furnished')),
            DropdownMenuItem(value: 'full', child: Text('Fully furnished')),
          ],
          onChanged: (value) => setState(() => _isFurnished = value),
        ),
      ],
    );
  }

  Widget _buildLandStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Land due-diligence', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _kittaController,
          decoration: const InputDecoration(labelText: 'Kitta number (optional)'),
        ),
        const SizedBox(height: 12),
        _enumDropdown('Lalpurja available', _lalpurjaAvailable, const {
          'yes': 'Yes',
          'no': 'No',
          'in_process': 'In process',
          'unknown': 'Unknown',
        }, (v) => setState(() => _lalpurjaAvailable = v)),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Road access'),
          value: _roadAccess,
          onChanged: (value) => setState(() => _roadAccess = value),
        ),
        if (_roadAccess) ...[
          TextField(
            controller: _roadWidthController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Road width (meters, optional)'),
          ),
          const SizedBox(height: 12),
          _enumDropdown('Road type', _roadType, const {
            'blacktop': 'Blacktop',
            'gravel': 'Gravel',
            'dirt': 'Dirt',
            'none': 'None',
          }, (v) => setState(() => _roadType = v)),
        ],
        const SizedBox(height: 12),
        _enumDropdown('Water access', _waterAccess, const {
          'municipal': 'Municipal',
          'well': 'Well',
          'none': 'None',
          'unknown': 'Unknown',
        }, (v) => setState(() => _waterAccess = v)),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Electricity access'),
          value: _electricityAccess,
          onChanged: (value) => setState(() => _electricityAccess = value),
        ),
        _enumDropdown('Drainage', _drainageAccess, const {
          'yes': 'Yes',
          'no': 'No',
          'unknown': 'Unknown',
        }, (v) => setState(() => _drainageAccess = v)),
        const SizedBox(height: 12),
        _enumDropdown('Land classification', _landClassification, const {
          'residential': 'Residential',
          'agricultural': 'Agricultural',
          'commercial': 'Commercial',
          'guthi': 'Guthi',
          'other': 'Other',
        }, (v) => setState(() => _landClassification = v)),
        const SizedBox(height: 12),
        _enumDropdown('Flood risk', _floodRisk, const {
          'none': 'None',
          'low': 'Low',
          'medium': 'Medium',
          'high': 'High',
          'unknown': 'Unknown',
        }, (v) => setState(() => _floodRisk = v)),
        const SizedBox(height: 12),
        _enumDropdown('Landslide risk', _landslideRisk, const {
          'none': 'None',
          'low': 'Low',
          'medium': 'Medium',
          'high': 'High',
          'unknown': 'Unknown',
        }, (v) => setState(() => _landslideRisk = v)),
        const SizedBox(height: 12),
        TextField(
          controller: _landNotesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Nearby development notes (optional)',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  /// Compact inline retry row for a failed dropdown/picker fetch — these are
  /// plain (non-autoDispose) FutureProviders, so without a manual `invalidate`
  /// call a failure would otherwise be cached forever with no way to retry.
  Widget _inlineLoadError(String message, VoidCallback onRetry) {
    return Row(
      children: [
        const Icon(Icons.error_outline, size: 18, color: AppColors.danger600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700)),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }

  Widget _enumDropdown(String label, String value, Map<String, String> options, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _buildMediaStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        const Text('Add at least one photo to continue.'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final media in _media)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: media.url,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Semantics(
                      button: true,
                      label: 'Remove photo',
                      child: GestureDetector(
                        onTap: _busy ? null : () => _deletePhoto(media),
                        child: const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.close, size: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            InkWell(
              onTap: _busy ? null : _pickPhotos,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _busy
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_a_photo_outlined),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPricingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Purpose', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [ButtonSegment(value: 'sale', label: Text('Sell')), ButtonSegment(value: 'rent', label: Text('Rent'))],
          selected: {_purpose},
          onSelectionChanged: (value) => setState(() => _purpose = value.first),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Price (Rs)'),
        ),
        if (_purpose == 'rent') ...[
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'monthly', label: Text('Monthly')),
              ButtonSegment(value: 'total', label: Text('Total')),
            ],
            selected: {_pricePeriod},
            onSelectionChanged: (value) => setState(() => _pricePeriod = value.first),
          ),
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Negotiable'),
          value: _negotiable,
          onChanged: (value) => setState(() => _negotiable = value),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              firstDate: now,
              lastDate: now.add(const Duration(days: 365)),
              initialDate: _availabilityDate ?? now,
            );
            if (picked != null) setState(() => _availabilityDate = picked);
          },
          icon: const Icon(Icons.event),
          label: Text(
            _availabilityDate == null
                ? 'Set availability date (optional)'
                : 'Available from ${_dateFormat.format(_availabilityDate!)}',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(labelText: 'Title', errorText: _titleError),
          onChanged: (_) {
            if (_titleError != null) setState(() => _titleError = null);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Description (optional)', alignLabelWithHint: true),
        ),
        const SizedBox(height: 16),
        Text('Amenities', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, _) {
            final amenities = ref.watch(amenitiesProvider);
            return amenities.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _inlineLoadError(
                'Could not load amenities.',
                () => ref.invalidate(amenitiesProvider),
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
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ready to publish', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(_titleController.text, style: Theme.of(context).textTheme.titleLarge),
        Text('${_media.length} photo${_media.length == 1 ? '' : 's'} added'),
        const SizedBox(height: 8),
        const Text(
          'Submitting for review sends it to Ghar Nepal\'s moderation queue before it goes live. '
          'Saving as draft keeps it on your Dashboard so you can finish it later.',
        ),
      ],
    );
  }

  String _titleCase(String value) => value[0].toUpperCase() + value.substring(1);
}
