import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/lookup/lookup_service.dart';
import '../../../../core/storage/saved_searches_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dwelleo_choice_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/property_query.dart';

/// Result of the filters sheet: the query to apply.
///
/// Mobile adaptation of the website's filter bar (Property Type ·
/// Beds & Baths · Price · More Filters) as a single bottom sheet.
/// Every control maps to a LIVE-VERIFIED filter param — nothing here sends
/// a parameter the backend ignores.
Future<PropertyQuery?> showPropertyFiltersSheet(
  BuildContext context, {
  required PropertyQuery current,
  required LookupService lookup,
  required SavedSearchesStore savedSearches,
}) {
  return showModalBottomSheet<PropertyQuery>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: 0.88,
      child: _FiltersSheet(
        current: current,
        lookup: lookup,
        savedSearches: savedSearches,
      ),
    ),
  );
}

/// Human label for a query, used for saved-search chips
/// ("Villa · Jeddah · 3+ beds · 500K–1M").
String describeQuery(
  PropertyQuery q, {
  required List<PropertyTypeOption> types,
  required List<CityOption> cities,
  required AppLocalizations l10n,
}) {
  final parts = <String>[
    if (q.listingType == 'for-sale') l10n.forSale,
    if (q.listingType == 'for-rent') l10n.forRent,
    ...types.where((t) => q.propertyTypeIds.contains(t.id)).map((t) => t.name),
    ...cities.where((c) => c.id == '${q.cityId}').map((c) => c.name),
    if (q.minBedrooms != null) '${q.minBedrooms}+ ${l10n.beds}',
    if (q.minBathrooms != null) '${q.minBathrooms}+ ${l10n.baths}',
    if (q.minPrice != null || q.maxPrice != null)
      [
        if (q.minPrice != null) q.minPrice!.round().toString(),
        if (q.maxPrice != null) q.maxPrice!.round().toString(),
      ].join('–'),
  ];
  return parts.isEmpty ? l10n.all : parts.join(' · ');
}

class _FiltersSheet extends StatefulWidget {
  final PropertyQuery current;
  final LookupService lookup;
  final SavedSearchesStore savedSearches;

  const _FiltersSheet({
    required this.current,
    required this.lookup,
    required this.savedSearches,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late PropertyQuery _draft;
  late final TextEditingController _minPrice;
  late final TextEditingController _maxPrice;

  List<PropertyTypeOption> _types = const [];
  List<CityOption> _cities = const [];
  List<SavedSearch> _saved = const [];

  static const List<String> _furnishing = [
    // CONFIRMED enum values from live data (REAL_API_SPEC).
    'unfurnished',
    'semi-furnished',
    'partially_furnished',
  ];

  @override
  void initState() {
    super.initState();
    _draft = widget.current;
    _minPrice = TextEditingController(
      text: widget.current.minPrice?.round().toString() ?? '',
    );
    _maxPrice = TextEditingController(
      text: widget.current.maxPrice?.round().toString() ?? '',
    );
    _loadData();
  }

  Future<void> _loadData() async {
    final saved = await widget.savedSearches.load();
    if (mounted) setState(() => _saved = saved);
    try {
      final types = await widget.lookup.propertyTypes();
      final cities = await widget.lookup.cities();
      if (mounted) {
        setState(() {
          _types = types;
          _cities = cities;
        });
      }
    } catch (_) {
      // Lookups failing only hides the type/city sections; the sheet
      // stays usable (beds/baths/price/furnishing).
    }
  }

  @override
  void dispose() {
    _minPrice.dispose();
    _maxPrice.dispose();
    super.dispose();
  }

  void _apply() {
    final min = num.tryParse(_minPrice.text.trim());
    final max = num.tryParse(_maxPrice.text.trim());
    Navigator.pop(
      context,
      _draft.copyWith(minPrice: () => min, maxPrice: () => max, page: 1),
    );
  }

  void _reset() {
    setState(() {
      _draft = PropertyQuery(listingType: widget.current.listingType);
      _minPrice.clear();
      _maxPrice.clear();
    });
  }

  void _applySaved(SavedSearch s) {
    Navigator.pop(
      context,
      PropertyQuery(
        listingType: s.listingType ?? widget.current.listingType,
        propertyTypeIds: s.propertyTypeIds,
        cityId: s.cityId,
        minBedrooms: s.minBedrooms,
        minBathrooms: s.minBathrooms,
        minPrice: s.minPrice,
        maxPrice: s.maxPrice,
        furnishingStatus: s.furnishingStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.filters,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              TextButton(onPressed: _reset, child: Text(l10n.reset)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 16),
            children: [
              if (_saved.isNotEmpty) ...[
                _SectionLabel(l10n.savedSearches),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _saved)
                      InputChip(
                        label: Text(s.label, overflow: TextOverflow.ellipsis),
                        onPressed: () => _applySaved(s),
                        onDeleted: () async {
                          final next = await widget.savedSearches.remove(
                            s.label,
                          );
                          if (mounted) setState(() => _saved = next);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
              _SectionLabel(l10n.propertyTypeLabel),
              if (_types.isEmpty)
                const _LookupLoading()
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in _types)
                      DwelleoChoiceChip(
                        label: t.name,
                        selected: _draft.propertyTypeIds.contains(t.id),
                        onTap: () => setState(() {
                          final ids = [..._draft.propertyTypeIds];
                          ids.contains(t.id) ? ids.remove(t.id) : ids.add(t.id);
                          _draft = _draft.copyWith(propertyTypeIds: ids);
                        }),
                      ),
                  ],
                ),
              const SizedBox(height: 18),
              _SectionLabel(l10n.city),
              if (_cities.isEmpty)
                const _LookupLoading()
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in _cities)
                      DwelleoChoiceChip(
                        label: c.name,
                        selected: '${_draft.cityId}' == c.id,
                        onTap: () => setState(() {
                          final id = int.tryParse(c.id);
                          _draft = _draft.copyWith(
                            cityId: () =>
                                '${_draft.cityId}' == c.id ? null : id,
                          );
                        }),
                      ),
                  ],
                ),
              const SizedBox(height: 18),
              _SectionLabel(l10n.bedrooms),
              _CountChips(
                selected: _draft.minBedrooms,
                onChanged: (v) => setState(
                  () => _draft = _draft.copyWith(minBedrooms: () => v),
                ),
                anyLabel: l10n.all,
              ),
              const SizedBox(height: 18),
              _SectionLabel(l10n.bathrooms),
              _CountChips(
                selected: _draft.minBathrooms,
                onChanged: (v) => setState(
                  () => _draft = _draft.copyWith(minBathrooms: () => v),
                ),
                anyLabel: l10n.all,
              ),
              const SizedBox(height: 18),
              _SectionLabel(l10n.priceRangeSar),
              Row(
                children: [
                  Expanded(
                    child: _PriceField(
                      controller: _minPrice,
                      hint: l10n.minPrice,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('—'),
                  ),
                  Expanded(
                    child: _PriceField(
                      controller: _maxPrice,
                      hint: l10n.maxPrice,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionLabel(l10n.furnishing),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in _furnishing)
                    DwelleoChoiceChip(
                      label: switch (f) {
                        'unfurnished' => l10n.furnishingUnfurnished,
                        'semi-furnished' => l10n.furnishingSemi,
                        _ => l10n.furnishingPartially,
                      },
                      selected: _draft.furnishingStatus == f,
                      onTap: () => setState(() {
                        _draft = _draft.copyWith(
                          furnishingStatus: () =>
                              _draft.furnishingStatus == f ? null : f,
                        );
                      }),
                    ),
                ],
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _apply,
                child: Text(l10n.showResults),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _LookupLoading extends StatelessWidget {
  const _LookupLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: LinearProgressIndicator(color: AppColors.primary, minHeight: 3),
    );
  }
}

/// "Any 1 2 3 4 5 6+" minimum-count chips.
class _CountChips extends StatelessWidget {
  final int? selected;
  final ValueChanged<int?> onChanged;
  final String anyLabel;

  const _CountChips({
    required this.selected,
    required this.onChanged,
    required this.anyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        DwelleoChoiceChip(
          label: anyLabel,
          selected: selected == null,
          onTap: () => onChanged(null),
        ),
        for (var i = 1; i <= 6; i++)
          DwelleoChoiceChip(
            label: i == 6 ? '6+' : '$i',
            selected: selected == i,
            onTap: () => onChanged(selected == i ? null : i),
          ),
      ],
    );
  }
}

class _PriceField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _PriceField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(hintText: hint, isDense: true),
    );
  }
}
