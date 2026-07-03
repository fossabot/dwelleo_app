import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/failure_l10n.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../properties/domain/entities/property.dart';
import 'featured_property_card.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import 'scroll_rail.dart';
import 'section_error_box.dart';
import 'section_header.dart';

/// "Some Excellent Properties" — horizontal rail of the API's curated
/// featured set, reusing the existing PropertyCard.
class FeaturedPropertiesSection extends StatelessWidget {
  const FeaturedPropertiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocSelector<HomeCubit, HomeState, SectionState<List<Property>>>(
      selector: (state) => state.featured,
      builder: (context, section) {
        if (section is SectionLoaded<List<Property>> && section.data.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: l10n.excellentProperties,
              actionLabel: l10n.viewAll,
              onAction: () => context.push(RoutePaths.propertySearchPath(null)),
            ),
            switch (section) {
              // Image-overlay cards (like the site + project cards): fixed 300.
              SectionLoading<List<Property>>() => const RailSkeleton(
                height: 300,
                itemWidth: 280,
              ),
              SectionError<List<Property>>(:final failure) => SectionErrorBox(
                message: failure.localized(l10n),
                onRetry: () => context.read<HomeCubit>().refresh(),
              ),
              SectionLoaded<List<Property>>(:final data) => ScrollRail(
                height: 300,
                itemCount: data.length,
                itemBuilder: (context, i) {
                  final property = data[i];
                  return SizedBox(
                    width: 280,
                    child: FeaturedPropertyCard(
                      property: property,
                      onTap: () => context.push(
                        RoutePaths.propertyDetailPath(property.slug),
                      ),
                    ),
                  );
                },
              ),
            },
          ],
        );
      },
    );
  }
}
