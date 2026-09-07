import 'package:flutter/material.dart';

import '../../../widgets/app_button.dart';
import '../../listings/data/models/search_filters.dart';

/// The filter form, mirroring the fields the website's
/// frontend/src/pages/Search/FilterPanel.tsx actually exposes: purpose,
/// property type, city (passed in from Home already, editable here too is
/// out of scope for this sheet — municipality filtering happens from the
/// Home city grid), min/max price, minimum bedrooms, sort, and — only for
/// land — lalpurja availability + road access.
class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key, required this.initial});

  final SearchFilters initial;

  static Future<SearchFilters?> show(BuildContext context, SearchFilters initial) {
    return showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterSheet(initial: initial),
    );
  }

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late String? _purpose = widget.initial.purpose;
  late String? _propertyType = widget.initial.propertyType;
  late final _minPriceController = TextEditingController(
    text: widget.initial.minPrice?.toStringAsFixed(0) ?? '',
  );
  late final _maxPriceController = TextEditingController(
    text: widget.initial.maxPrice?.toStringAsFixed(0) ?? '',
  );
  late int? _bedroomsMin = widget.initial.bedroomsMin;
  late String _sort = widget.initial.sort;
  late String? _lalpurja = widget.initial.lalpurjaAvailable;
  late bool _roadAccess = widget.initial.roadAccess ?? false;

  static const _propertyTypes = ['room', 'apartment', 'house', 'land', 'commercial'];

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _apply() {
    Navigator.of(context).pop(
      SearchFilters(
        purpose: _purpose,
        propertyType: _propertyType,
        minPrice: double.tryParse(_minPriceController.text),
        maxPrice: double.tryParse(_maxPriceController.text),
        bedroomsMin: _bedroomsMin,
        municipalityId: widget.initial.municipalityId,
        q: widget.initial.q,
        sort: _sort,
        lalpurjaAvailable: _propertyType == 'land' ? _lalpurja : null,
        roadAccess: _propertyType == 'land' ? _roadAccess : null,
      ),
    );
  }

  void _reset() {
    Navigator.of(context).pop(const SearchFilters());
  }

  @override
  Widget build(BuildContext context) {
    final isLand = _propertyType == 'land';

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
              Row(
                children: [
                  Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  TextButton(onPressed: _reset, child: const Text('Reset')),
                ],
              ),
              const SizedBox(height: 12),
              Text('Purpose', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<String?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('Any')),
                  ButtonSegment(value: 'sale', label: Text('Buy')),
                  ButtonSegment(value: 'rent', label: Text('Rent')),
                ],
                selected: {_purpose},
                onSelectionChanged: (value) => setState(() => _purpose = value.first),
              ),
              const SizedBox(height: 16),
              Text('Property type', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _propertyType,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any type')),
                  ..._propertyTypes.map((type) => DropdownMenuItem(value: type, child: Text(_titleCase(type)))),
                ],
                onChanged: (value) => setState(() => _propertyType = value),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Min price (Rs)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max price (Rs)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Minimum bedrooms', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                initialValue: _bedroomsMin,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any')),
                  ...List.generate(5, (i) => i + 1).map(
                    (n) => DropdownMenuItem(value: n, child: Text(n == 5 ? '5+' : '$n+')),
                  ),
                ],
                onChanged: (value) => setState(() => _bedroomsMin = value),
              ),
              if (isLand) ...[
                const SizedBox(height: 16),
                Text('Lalpurja availability', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: _lalpurja,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Any')),
                    DropdownMenuItem(value: 'yes', child: Text('Available')),
                    DropdownMenuItem(value: 'in_process', child: Text('In process')),
                    DropdownMenuItem(value: 'no', child: Text('Not available')),
                  ],
                  onChanged: (value) => setState(() => _lalpurja = value),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Road access only'),
                  value: _roadAccess,
                  onChanged: (value) => setState(() => _roadAccess = value ?? false),
                ),
              ],
              const SizedBox(height: 16),
              Text('Sort by', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _sort,
                items: const [
                  DropdownMenuItem(value: 'newest', child: Text('Newest')),
                  DropdownMenuItem(value: 'price_asc', child: Text('Price: low to high')),
                  DropdownMenuItem(value: 'price_desc', child: Text('Price: high to low')),
                ],
                onChanged: (value) => setState(() => _sort = value ?? 'newest'),
              ),
              const SizedBox(height: 24),
              AppButton(label: 'Show results', onPressed: _apply),
            ],
          ),
        ),
      ),
    );
  }

  String _titleCase(String value) => value[0].toUpperCase() + value.substring(1);
}
