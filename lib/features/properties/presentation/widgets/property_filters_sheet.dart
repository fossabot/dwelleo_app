import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/lookup/lookup_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/property_query.dart';

/// dwelleo.sa's "Filters" sheet: City, Price Range, Area, Bedrooms, Bathrooms,
/// with Reset All / Apply. Returns a [PropertyQuery] that PRESERVES the screen's
/// base context (listing type, property type, developer, sort) and applies the
/// chosen filters — cleared fields become null (so filters can be removed).
Future<PropertyQuery?> showPropertyFiltersSheet(
  BuildContext context,
  PropertyQuery base,
) {
  return showModalBottomSheet<PropertyQuery>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FiltersSheet(base: base),
  );
}

class _FiltersSheet extends StatefulWidget {
  final PropertyQuery base;
  const _FiltersSheet({required this.base});

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late final TextEditingController _minPrice;
  late final TextEditingController _maxPrice;
  late final TextEditingController _minArea;
  late final TextEditingController _maxArea;

  int? _cityId;
  int? _beds;
  int? _baths;
  List<CityOption> _cities = const [];

  @override
  void initState() {
    super.initState();
    final b = widget.base;
    _cityId = b.cityId;
    _beds = b.minBedrooms;
    _baths = b.minBathrooms;
    _minPrice = TextEditingController(text: b.minPrice?.toString() ?? '');
    _maxPrice = TextEditingController(text: b.maxPrice?.toString() ?? '');
    _minArea = TextEditingController(text: b.minArea?.toString() ?? '');
    _maxArea = TextEditingController(text: b.maxArea?.toString() ?? '');
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await sl<LookupService>().cities();
      if (mounted) setState(() => _cities = cities);
    } catch (_) {
      /* dropdown stays empty; non-fatal */
    }
  }

  @override
  void dispose() {
    _minPrice.dispose();
    _maxPrice.dispose();
    _minArea.dispose();
    _maxArea.dispose();
    super.dispose();
  }

  num? _num(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : num.tryParse(t);
  }

  void _reset() {
    setState(() {
      _cityId = null;
      _beds = null;
      _baths = null;
      _minPrice.clear();
      _maxPrice.clear();
      _minArea.clear();
      _maxArea.clear();
    });
  }

  void _apply() {
    final b = widget.base;
    // Rebuild from base context so cleared filters become null.
    Navigator.pop(
      context,
      PropertyQuery(
        listingType: b.listingType,
        propertyTypeId: b.propertyTypeId,
        developerId: b.developerId,
        regionId: b.regionId,
        areaId: b.areaId,
        furnishingStatus: b.furnishingStatus,
        onlyFavorites: b.onlyFavorites,
        sort: b.sort,
        cityId: _cityId,
        minPrice: _num(_minPrice),
        maxPrice: _num(_maxPrice),
        minArea: _num(_minArea),
        maxArea: _num(_maxArea),
        minBedrooms: _beds,
        minBathrooms: _baths,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = context.read<LocaleCubit>().state.languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
                child: Row(
                  children: [
                    Icon(Icons.tune, color: accent),
                    const SizedBox(width: 10),
                    Text(
                      ar ? 'الفلاتر' : 'Filters',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  children: [
                    _label(ar ? 'المدينة' : 'City'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _cityId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: ar ? 'اختر' : 'Choose',
                      ),
                      items: _cities
                          .map(
                            (c) => DropdownMenuItem(
                              value: int.tryParse(c.id),
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _cityId = v),
                    ),
                    const SizedBox(height: 20),
                    _label(ar ? 'نطاق السعر (ريال)' : 'Price Range (SAR)'),
                    const SizedBox(height: 8),
                    _pairRow(
                      leftHint: ar ? 'من' : 'From',
                      rightHint: ar ? 'إلى' : 'To',
                      leftLabel: ar ? 'أقل سعر' : 'Min Price',
                      rightLabel: ar ? 'أعلى سعر' : 'Max Price',
                      left: _minPrice,
                      right: _maxPrice,
                    ),
                    const SizedBox(height: 20),
                    _label(ar ? 'المساحة (م²)' : 'Area (m²)'),
                    const SizedBox(height: 8),
                    _pairRow(
                      leftHint: '0',
                      rightHint: '10000',
                      leftLabel: ar ? 'أقل مساحة' : 'Min Area',
                      rightLabel: ar ? 'أعلى مساحة' : 'Max Area',
                      left: _minArea,
                      right: _maxArea,
                    ),
                    const SizedBox(height: 20),
                    _label(ar ? 'غرف النوم' : 'Bedrooms'),
                    const SizedBox(height: 8),
                    _chips(
                      values: const [1, 2, 3, 4, 5],
                      labels: const ['1', '2', '3', '4', '5+'],
                      selected: _beds,
                      onTap: (v) =>
                          setState(() => _beds = _beds == v ? null : v),
                      accent: accent,
                      scheme: scheme,
                    ),
                    const SizedBox(height: 20),
                    _label(ar ? 'دورات المياه' : 'Bathrooms'),
                    const SizedBox(height: 8),
                    _chips(
                      values: const [1, 2, 3, 4],
                      labels: const ['1', '2', '3', '4+'],
                      selected: _baths,
                      onTap: (v) =>
                          setState(() => _baths = _baths == v ? null : v),
                      accent: accent,
                      scheme: scheme,
                    ),
                  ],
                ),
              ),
              // Footer.
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _reset,
                          child: Text(ar ? 'إعادة تعيين' : 'Reset All'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _apply,
                          child: Text(ar ? 'تطبيق الفلاتر' : 'Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
  );

  Widget _pairRow({
    required String leftHint,
    required String rightHint,
    required String leftLabel,
    required String rightLabel,
    required TextEditingController left,
    required TextEditingController right,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _numField(leftLabel, leftHint, left)),
        const SizedBox(width: 12),
        Expanded(child: _numField(rightLabel, rightHint, right)),
      ],
    );
  }

  Widget _numField(String label, String hint, TextEditingController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  Widget _chips({
    required List<int> values,
    required List<String> labels,
    required int? selected,
    required ValueChanged<int> onTap,
    required Color accent,
    required ColorScheme scheme,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < values.length; i++)
          _CircleChoice(
            label: labels[i],
            selected: selected == values[i],
            accent: accent,
            scheme: scheme,
            onTap: () => onTap(values[i]),
          ),
      ],
    );
  }
}

class _CircleChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _CircleChoice({
    required this.label,
    required this.selected,
    required this.accent,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? accent : Colors.transparent,
          border: Border.all(
            color: selected ? accent : scheme.outline,
            width: 1.4,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected
                ? AppColors.onAccentFor(Theme.of(context).brightness)
                : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
