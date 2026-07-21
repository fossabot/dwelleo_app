import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/failure_l10n.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/project.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import 'home_choice_chip.dart';
import 'project_card.dart';
import 'scroll_rail.dart';
import 'section_error_box.dart';
import 'section_header.dart';

/// "Explore Projects by Cities" — city chips + horizontal project rail.
/// The selected chip is local UI state; data comes from HomeCubit.
class ProjectsSection extends StatefulWidget {
  const ProjectsSection({super.key});

  @override
  State<ProjectsSection> createState() => _ProjectsSectionState();
}

class _ProjectsSectionState extends State<ProjectsSection> {
  String? _city;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocSelector<HomeCubit, HomeState, SectionState<List<Project>>>(
      selector: (state) => state.projects,
      builder: (context, section) {
        if (section is SectionLoaded<List<Project>> && section.data.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: l10n.exploreProjectsLead,
              accent: l10n.exploreProjectsAccent,
              subtitle: l10n.exploreProjectsSubtitle,
              actionLabel: l10n.viewAll,
              onAction: () => context.push(RoutePaths.explore),
            ),
            switch (section) {
              SectionLoading<List<Project>>() => const RailSkeleton(
                height: 300,
                itemWidth: 230,
              ),
              SectionError<List<Project>>(:final failure) => SectionErrorBox(
                message: failure.localized(l10n),
                onRetry: () => context.read<HomeCubit>().refresh(),
              ),
              SectionLoaded<List<Project>>(:final data) => _Rail(
                projects: data,
                city: _city,
                onCity: (c) => setState(() => _city = c),
              ),
            },
          ],
        );
      },
    );
  }
}

class _Rail extends StatelessWidget {
  final List<Project> projects;
  final String? city;
  final ValueChanged<String?> onCity;

  const _Rail({
    required this.projects,
    required this.city,
    required this.onCity,
  });

  @override
  Widget build(BuildContext context) {
    final cities = <String>[];
    final seen = <String>{};
    for (final p in projects) {
      final name = p.cityName;
      if (name != null && seen.add(name)) cities.add(name);
    }
    final filtered = city == null
        ? projects
        : projects.where((p) => p.cityName == city).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: cities.length + 1,
            separatorBuilder: (ctx, i) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final label = i == 0
                  ? AppLocalizations.of(context).all
                  : cities[i - 1];
              final value = i == 0 ? null : cities[i - 1];
              return HomeChoiceChip(
                label: label,
                selected: city == value,
                onTap: () => onCity(value),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const SizedBox(height: 300)
        else
          ScrollRail(
            height: 300,
            itemCount: filtered.length,
            itemBuilder: (context, i) =>
                ProjectCard(project: filtered[i], width: 230),
          ),
      ],
    );
  }
}
