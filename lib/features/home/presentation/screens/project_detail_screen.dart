import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/failure_l10n.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dwelleo_images.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/html_text.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../properties/domain/entities/property_query.dart';
import '../../domain/entities/developer.dart';
import '../../domain/entities/project.dart';
import '../cubit/project_detail_cubit.dart';

/// FULL project page (owner review: a sheet is wrong — the site has a real
/// route with hero, developer, dates, overview, features and CTA).
/// Data: VERIFIED GET /projects/{id}.
class ProjectDetailScreen extends StatefulWidget {
  final int projectId;

  /// Optional list item for instant paint while the detail loads.
  final Project? preview;

  const ProjectDetailScreen({super.key, required this.projectId, this.preview});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late final ProjectDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<ProjectDetailCubit>()
      ..load(widget.projectId, preview: widget.preview);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: BlocBuilder<ProjectDetailCubit, ProjectDetailState>(
        bloc: _cubit,
        builder: (context, state) => switch (state) {
          ProjectDetailLoading(:final preview) =>
            preview != null
                ? _Body(project: preview, loading: true)
                : const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
          ProjectDetailLoaded(:final project) => _Body(project: project),
          ProjectDetailError(:final failure, :final preview) =>
            preview != null
                ? _Body(project: preview)
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            failure.localized(l10n),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          FilledButton(
                            onPressed: () => _cubit.load(
                              widget.projectId,
                              preview: widget.preview,
                            ),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    ),
                  ),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Project project;
  final bool loading;

  const _Body({required this.project, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);
    final overview = project.overviewDescription == null
        ? null
        : HtmlText.strip(project.overviewDescription!);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (project.image != null)
                  CachedNetworkImage(
                    imageUrl: DwelleoImages.optimized(
                      project.image!.displayThumb,
                      width: 1080,
                    ),
                    httpHeaders: DwelleoImages.headers,
                    fit: BoxFit.cover,
                  )
                else
                  ColoredBox(color: scheme.surfaceContainerHighest),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.35, 1],
                      colors: [Colors.transparent, Color(0xCC000000)],
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: 16,
                  end: 16,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (project.isOffPlan)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.offPlan,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        project.name,
                        style: const TextStyle(
                          fontSize: 24,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if (project.city != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              project.city!.name,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (loading)
                  const Align(
                    alignment: Alignment.topCenter,
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      color: AppColors.primary,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (project.startingPrice != null) ...[
                  Text(
                    l10n.startingFrom,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      SvgPicture.asset(
                        AppSvg.sar,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          scheme.onSurface,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        Formatters.priceValue(project.startingPrice),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                // Developer card → full profile route.
                if (project.developer != null)
                  _DeveloperTile(developer: project.developer!),
                const SizedBox(height: 14),
                _InfoRow(
                  icon: Icons.rocket_launch_outlined,
                  label: l10n.launchDate,
                  value: project.launchDate,
                ),
                _InfoRow(
                  icon: Icons.event_available_outlined,
                  label: l10n.expectedHandover,
                  value: project.expectedHandoverDate,
                ),
                _InfoRow(
                  icon: Icons.place_outlined,
                  label: l10n.city,
                  value: project.city?.name ?? project.locationLabel,
                ),
                if (project.keyFeatures.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.keyFeatures,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final feature in project.keyFeatures)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (overview != null && overview.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.overview,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    overview,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.55,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (project.amenityNames.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.amenities,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final amenity in project.amenityNames)
                        Chip(label: Text(amenity)),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.push(
                      RoutePaths.propertySearch,
                      extra: PropertyQuery(projectId: project.id),
                    ),
                    icon: const Icon(Icons.home_work_outlined, size: 19),
                    label: Text(l10n.viewProperties),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DeveloperTile extends StatelessWidget {
  final ProjectDeveloper developer;

  const _DeveloperTile({required this.developer});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        // Carry the partner we already have; without this the profile has
        // nothing to paint and falls back to a bare "#1804".
        onTap: () => context.push(
          RoutePaths.developerProfilePath(developer.id),
          extra: Developer(
            id: developer.id,
            name: developer.name,
            image: developer.image,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                backgroundImage: developer.image == null
                    ? null
                    : CachedNetworkImageProvider(
                        DwelleoImages.optimized(
                          developer.image!.displayThumb,
                          width: 640,
                        ),
                        headers: DwelleoImages.headers,
                      ),
                child: developer.image == null
                    ? const Icon(Icons.business_rounded, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.developerLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      developer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (developer.isVerified)
                Icon(
                  Icons.verified_rounded,
                  size: 20,
                  color: AppColors.accentFor(Theme.of(context).brightness),
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const _InfoRow({required this.icon, required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 17, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          ),
          const Spacer(),
          Text(
            value!,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
