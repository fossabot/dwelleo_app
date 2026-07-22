import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dwelleo_images.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/developer.dart';
import '../../domain/entities/project.dart';
import '../cubit/explore_cubit.dart';
import '../cubit/explore_state.dart';
import '../widgets/project_card.dart';

/// FULL developer/broker profile route (owner review: cards must open a
/// screen like the site's /developers/{id} page).
///
/// HONESTY NOTE: GET /developers/{id} returns 404 on the live API (probed
/// 2026-07-22) — the site renders it from SSR data. So this screen builds
/// from the list payload we already carry + LIVE sections that ARE
/// verified: the partner's projects (client-filtered /projects) and their
/// listings (`filter[developer_id]`). The bio text lands when the backend
/// ships the endpoint.
class DeveloperProfileScreen extends StatefulWidget {
  final int developerId;
  final Developer? preview;

  const DeveloperProfileScreen({
    super.key,
    required this.developerId,
    this.preview,
  });

  @override
  State<DeveloperProfileScreen> createState() => _DeveloperProfileScreenState();
}

class _DeveloperProfileScreenState extends State<DeveloperProfileScreen> {
  late final ExploreCubit _projects;

  @override
  void initState() {
    super.initState();
    // Reuses the projects feed (cached endpoint) to show this partner's
    // developments — real data, no invented endpoint.
    _projects = sl<ExploreCubit>()..load();
  }

  @override
  void dispose() {
    _projects.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);
    final developer = widget.preview;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.developerLabel)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: developer?.image == null
                  ? Icon(Icons.business_rounded, size: 38, color: accent)
                  : CachedNetworkImage(
                      imageUrl: DwelleoImages.optimized(
                        developer!.image!.displayThumb,
                        width: 640,
                      ),
                      httpHeaders: DwelleoImages.headers,
                      fit: BoxFit.contain,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            developer?.name ?? '#${widget.developerId}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if ((developer?.rating ?? 0) > 0)
                _Chip(
                  icon: Icons.star_rounded,
                  label: developer!.rating.toStringAsFixed(1),
                ),
              if (developer?.featured == true ||
                  developer?.featuredInHome == true)
                _Chip(
                  icon: Icons.workspace_premium_rounded,
                  label: l10n.featured,
                ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push(
                RoutePaths.propertySearchPath(
                  null,
                  developerId: widget.developerId,
                ),
                extra: developer?.name.trim(),
              ),
              icon: const Icon(Icons.home_work_outlined, size: 19),
              label: Text(l10n.viewProperties),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.viewPropertiesHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: accent),
          ),
          const SizedBox(height: 20),
          // Their projects (live /projects, filtered client-side by owner id).
          BlocBuilder<ExploreCubit, ExploreState>(
            bloc: _projects,
            builder: (context, state) {
              final all = switch (state) {
                ExploreLoaded(all: final projects) => projects,
                _ => const <Project>[],
              };
              final theirs = all
                  .where((p) => p.developer?.id == widget.developerId)
                  .toList(growable: false);
              if (theirs.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.projects,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final project in theirs) ...[
                    ProjectCard(project: project, height: 220),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
