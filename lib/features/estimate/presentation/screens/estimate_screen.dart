import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/failure_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/domain/entities/city_market_stat.dart';
import '../../domain/entities/estimate_models.dart';
import '../cubit/estimate_cubit.dart';
import '../widgets/estimate_controls.dart';
import '../widgets/estimate_result_view.dart';

/// Estimate Property — the site's 6-phase wizard, rebuilt for mobile.
///
/// Parity captured live from dwelleo.sa/en/Estimate: step eyebrow, animated
/// progress, per-step gates, the optional accuracy booster, and the result
/// card. Valuation runs over VERIFIED /market/districts numbers and the
/// finished estimate is written to the on-device database.
class EstimateScreen extends StatefulWidget {
  const EstimateScreen({super.key});

  @override
  State<EstimateScreen> createState() => _EstimateScreenState();
}

class _EstimateScreenState extends State<EstimateScreen> {
  late final EstimateCubit _cubit;
  final TextEditingController _area = TextEditingController();
  final TextEditingController _year = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = sl<EstimateCubit>()..loadCities();
  }

  @override
  void dispose() {
    _area.dispose();
    _year.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.estimateProperty)),
      body: BlocBuilder<EstimateCubit, EstimateState>(
        bloc: _cubit,
        builder: (context, state) => switch (state) {
          EstimateCalculating() => _Analysing(l10n: l10n),
          EstimateReady(:final input, :final result) => EstimateResultView(
            input: input,
            result: result,
            onRestart: () {
              _area.clear();
              _year.clear();
              _cubit.reset();
            },
          ),
          EstimateFailed(:final failure) => _Failed(
            message: failure.localized(l10n),
            onRetry: _cubit.calculate,
            onBack: () => _cubit.goTo(EstimateStep.location),
            l10n: l10n,
          ),
          EstimateEditing() => _Wizard(
            state: state,
            cubit: _cubit,
            area: _area,
            year: _year,
          ),
        },
      ),
    );
  }
}

class _Wizard extends StatelessWidget {
  final EstimateEditing state;
  final EstimateCubit cubit;
  final TextEditingController area;
  final TextEditingController year;

  const _Wizard({
    required this.state,
    required this.cubit,
    required this.area,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);
    final isBoost = state.step == EstimateStep.boost;
    final stepNumber = state.step.index + 1;

    return Column(
      children: [
        // ── Header: eyebrow, title, animated progress ──────────────────
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 6, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBoost
                    ? l10n.estimateOptional
                    : l10n.estimateStepOf(stepNumber, 6),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: accent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _title(l10n, state.step),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _subtitle(l10n, state.step),
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: state.progress),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor: scheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(value * 100).round()}%',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        Expanded(
          // Align keeps each step pinned to the top; without it the
          // switcher centres short steps in a large blank area.
          child: Align(
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: SingleChildScrollView(
                key: ValueKey(state.step),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StepBody(
                      state: state,
                      cubit: cubit,
                      area: area,
                      year: year,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Footer: gate hint + Back/Next ──────────────────────────────
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 12),
            child: Column(
              children: [
                if (!state.canAdvance)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      state.step == EstimateStep.location
                          ? l10n.estimateGateLocation
                          : l10n.estimateGateDetails,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    if (state.step != EstimateStep.purpose)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: cubit.back,
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            size: 20,
                          ),
                          label: Text(l10n.back),
                        ),
                      ),
                    if (state.step != EstimateStep.purpose)
                      const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: !state.canAdvance
                            ? null
                            : (state.step == EstimateStep.features || isBoost)
                            ? cubit.calculate
                            : cubit.next,
                        icon: Icon(
                          state.step == EstimateStep.features || isBoost
                              ? Icons.auto_awesome_rounded
                              : Icons.chevron_right_rounded,
                          size: 19,
                        ),
                        label: Text(
                          state.step == EstimateStep.features || isBoost
                              ? l10n.estimateSeeResult
                              : l10n.next,
                        ),
                      ),
                    ),
                  ],
                ),
                if (state.step == EstimateStep.features)
                  TextButton(
                    onPressed: () => cubit.goTo(EstimateStep.boost),
                    child: Text(l10n.estimateImproveAccuracy),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _title(AppLocalizations l10n, EstimateStep step) =>
      switch (step) {
        EstimateStep.purpose => l10n.estimatePurposeTitle,
        EstimateStep.location => l10n.estimateLocationTitle,
        EstimateStep.propertyType => l10n.estimateTypeTitle,
        EstimateStep.details => l10n.estimateDetailsTitle,
        EstimateStep.condition => l10n.estimateConditionTitle,
        EstimateStep.features => l10n.estimateFeaturesTitle,
        EstimateStep.boost => l10n.estimateBoostTitle,
        EstimateStep.result => l10n.estimateResultTitle,
      };

  static String _subtitle(AppLocalizations l10n, EstimateStep step) =>
      switch (step) {
        EstimateStep.purpose => l10n.estimatePurposeSubtitle,
        EstimateStep.location => l10n.estimateLocationSubtitle,
        EstimateStep.propertyType => l10n.estimateTypeSubtitle,
        EstimateStep.details => l10n.estimateDetailsSubtitle,
        EstimateStep.condition => l10n.estimateConditionSubtitle,
        EstimateStep.features => l10n.estimateFeaturesSubtitle,
        EstimateStep.boost => l10n.estimateBoostSubtitle,
        EstimateStep.result => '',
      };
}

class _StepBody extends StatelessWidget {
  final EstimateEditing state;
  final EstimateCubit cubit;
  final TextEditingController area;
  final TextEditingController year;

  const _StepBody({
    required this.state,
    required this.cubit,
    required this.area,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final input = state.input;

    return switch (state.step) {
      // ── 1. Purpose ────────────────────────────────────────────────────
      EstimateStep.purpose => Column(
        children: [
          EstimateOptionCard(
            label: l10n.estimateSell,
            sublabel: l10n.estimateSellHint,
            icon: Icons.sell_outlined,
            selected: input.purpose == EstimatePurpose.sell,
            onTap: () =>
                cubit.update(input.copyWith(purpose: EstimatePurpose.sell)),
          ),
          const SizedBox(height: 10),
          EstimateOptionCard(
            label: l10n.estimateRent,
            sublabel: l10n.estimateRentHint,
            icon: Icons.vpn_key_outlined,
            selected: input.purpose == EstimatePurpose.rent,
            onTap: () =>
                cubit.update(input.copyWith(purpose: EstimatePurpose.rent)),
          ),
        ],
      ),

      // ── 2. Location ───────────────────────────────────────────────────
      EstimateStep.location => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EstimateSectionLabel(label: l10n.city),
          DropdownButtonFormField<int>(
            initialValue: input.cityId,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: l10n.city,
              prefixIcon: const Icon(Icons.location_on_outlined, size: 19),
            ),
            items: [
              for (final city in state.cities)
                DropdownMenuItem(
                  value: int.tryParse(city.id) ?? -1,
                  child: Text(city.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              final name = state.cities
                  .firstWhere((c) => (int.tryParse(c.id) ?? -1) == value)
                  .name;
              cubit.selectCity(value, name);
            },
          ),
          const SizedBox(height: 16),
          EstimateSectionLabel(label: l10n.district),
          if (state.loadingDistricts)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: LinearProgressIndicator(minHeight: 3),
            )
          else
            DropdownButtonFormField<int>(
              initialValue: input.districtId,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: state.districts.isEmpty
                    ? l10n.estimateGateLocation
                    : l10n.district,
                prefixIcon: const Icon(Icons.map_outlined, size: 19),
              ),
              items: [
                for (final d in state.districts)
                  DropdownMenuItem(
                    value: d.districtId,
                    child: Text(d.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: state.districts.isEmpty
                  ? null
                  : (value) {
                      if (value == null) return;
                      final name = state.districts
                          .firstWhere((d) => d.districtId == value)
                          .name;
                      cubit.selectDistrict(value, name);
                    },
            ),
        ],
      ),

      // ── 3. Property type ──────────────────────────────────────────────
      EstimateStep.propertyType => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EstimateOptionCard(
            label: l10n.apartment,
            icon: Icons.apartment_rounded,
            selected: input.unitTypeId == MarketUnitTypes.apartment,
            onTap: () => cubit.update(
              input.copyWith(unitTypeId: MarketUnitTypes.apartment),
            ),
          ),
          const SizedBox(height: 10),
          EstimateOptionCard(
            label: l10n.villa,
            icon: Icons.villa_rounded,
            selected: input.unitTypeId == MarketUnitTypes.villa,
            onTap: () =>
                cubit.update(input.copyWith(unitTypeId: MarketUnitTypes.villa)),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.estimateTypesComingSoon,
            style: TextStyle(
              fontSize: 11.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),

      // ── 4. Details ────────────────────────────────────────────────────
      EstimateStep.details => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EstimateSectionLabel(label: l10n.estimateAreaAndRooms),
          _FieldLabel(
            label: l10n.estimateFloorArea,
            impactLabel: l10n.estimateHighImpact,
          ),
          TextField(
            controller: area,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '0',
              suffixText: l10n.sqm,
              prefixIcon: const Icon(Icons.square_foot_rounded, size: 19),
            ),
            onChanged: (value) => cubit.update(
              input.copyWith(areaSqm: () => num.tryParse(value)),
            ),
          ),
          const SizedBox(height: 4),
          const SizedBox(height: 4),
          EstimateStepperField(
            label: l10n.beds,
            impactLabel: l10n.estimateHighImpact,
            value: input.bedrooms,
            onChanged: (v) => cubit.update(input.copyWith(bedrooms: v)),
          ),
          EstimateStepperField(
            label: l10n.estimateLivingRooms,
            value: input.livingRooms,
            onChanged: (v) => cubit.update(input.copyWith(livingRooms: v)),
          ),
          EstimateStepperField(
            label: l10n.baths,
            value: input.bathrooms,
            onChanged: (v) => cubit.update(input.copyWith(bathrooms: v)),
          ),
          const SizedBox(height: 10),
          EstimateSectionLabel(label: l10n.estimateBuilding),
          _FieldLabel(label: l10n.estimateYearBuilt),
          TextField(
            controller: year,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              hintText: '____',
              prefixIcon: const Icon(Icons.event_outlined, size: 19),
            ),
            onChanged: (value) => cubit.update(
              input.copyWith(yearBuilt: () => int.tryParse(value)),
            ),
          ),
          EstimateStepperField(
            label: l10n.estimateStreetsFacing,
            value: input.streetsFacing,
            max: 4,
            onChanged: (v) => cubit.update(input.copyWith(streetsFacing: v)),
          ),
        ],
      ),

      // ── 5. Condition ──────────────────────────────────────────────────
      EstimateStep.condition => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EstimateSectionLabel(label: l10n.estimateInterior),
          EstimateToggleRow(
            label: l10n.estimateFittedKitchen,
            icon: Icons.countertops_outlined,
            value: input.fittedKitchen,
            onChanged: (v) => cubit.update(input.copyWith(fittedKitchen: v)),
          ),
          EstimateToggleRow(
            label: l10n.estimateFurnished,
            icon: Icons.chair_outlined,
            value: input.furnished,
            onChanged: (v) => cubit.update(input.copyWith(furnished: v)),
          ),
          EstimateToggleRow(
            label: l10n.estimateAcInstalled,
            icon: Icons.ac_unit_rounded,
            value: input.acInstalled,
            onChanged: (v) => cubit.update(input.copyWith(acInstalled: v)),
          ),
          if (input.acInstalled) ...[
            const SizedBox(height: 12),
            EstimateSectionLabel(label: l10n.estimateAcType),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in AcType.values)
                  ChoiceChip(
                    label: Text(_acLabel(l10n, type)),
                    selected: input.acType == type,
                    onSelected: (_) =>
                        cubit.update(input.copyWith(acType: type)),
                  ),
              ],
            ),
          ],
        ],
      ),

      // ── 6. Features ───────────────────────────────────────────────────
      EstimateStep.features => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EstimateSectionLabel(label: l10n.amenities),
          EstimateToggleRow(
            label: l10n.estimateElevator,
            icon: Icons.elevator_outlined,
            value: input.elevator,
            onChanged: (v) => cubit.update(input.copyWith(elevator: v)),
          ),
          EstimateToggleRow(
            label: l10n.estimateParking,
            icon: Icons.local_parking_rounded,
            value: input.parking,
            onChanged: (v) => cubit.update(input.copyWith(parking: v)),
          ),
          EstimateToggleRow(
            label: l10n.estimateStorageRoom,
            icon: Icons.inventory_2_outlined,
            value: input.storageRoom,
            onChanged: (v) => cubit.update(input.copyWith(storageRoom: v)),
          ),
          EstimateToggleRow(
            label: l10n.estimateSecurity,
            icon: Icons.shield_outlined,
            value: input.security247,
            onChanged: (v) => cubit.update(input.copyWith(security247: v)),
          ),
        ],
      ),

      // ── Optional accuracy booster ─────────────────────────────────────
      EstimateStep.boost => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EstimateSectionLabel(label: l10n.estimateFacing),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final dir in FacingDirection.values)
                ChoiceChip(
                  label: Text(_facingLabel(l10n, dir)),
                  selected: input.facing == dir,
                  onSelected: (selected) => cubit.update(
                    input.copyWith(facing: () => selected ? dir : null),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          EstimateSectionLabel(label: l10n.estimateExtras),
          EstimateToggleRow(
            label: l10n.estimateBalcony,
            icon: Icons.balcony_outlined,
            value: input.balcony,
            onChanged: (v) => cubit.update(input.copyWith(balcony: v)),
          ),
        ],
      ),

      EstimateStep.result => const SizedBox.shrink(),
    };
  }

  static String _acLabel(AppLocalizations l10n, AcType type) => switch (type) {
    AcType.none => l10n.estimateAcNone,
    AcType.split => l10n.estimateAcSplit,
    AcType.central => l10n.estimateAcCentral,
    AcType.concealed => l10n.estimateAcConcealed,
  };

  static String _facingLabel(AppLocalizations l10n, FacingDirection dir) =>
      switch (dir) {
        FacingDirection.north => l10n.estimateNorth,
        FacingDirection.east => l10n.estimateEast,
        FacingDirection.south => l10n.estimateSouth,
        FacingDirection.west => l10n.estimateWest,
      };
}

class _Analysing extends StatelessWidget {
  final AppLocalizations l10n;

  const _Analysing({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(Theme.of(context).brightness);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: accent),
          const SizedBox(height: 16),
          Text(
            l10n.estimateAnalysing,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final AppLocalizations l10n;

  const _Failed({
    required this.message,
    required this.onRetry,
    required this.onBack,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.query_stats_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
            TextButton(onPressed: onBack, child: Text(l10n.back)),
          ],
        ),
      ),
    );
  }
}

/// Field label rendered ABOVE the input (the floating label collided with
/// the outlined border on the number fields).
class _FieldLabel extends StatelessWidget {
  final String label;
  final String? impactLabel;

  const _FieldLabel({required this.label, this.impactLabel});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          if (impactLabel != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart_rounded, size: 12, color: accent),
                  const SizedBox(width: 3),
                  Text(
                    impactLabel!,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
