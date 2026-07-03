import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dwelleo_images.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/arrow_badge.dart';
import '../../domain/entities/project.dart';
import 'project_details_sheet.dart';

/// Image-first project card in the dwelleo.sa style: full-bleed photo,
/// bottom gradient, name + city + "Starting From" price overlay, and the
/// site's ↗ affordance. Tapping opens the project quick-look sheet
/// (built from the already-loaded entity — no extra API call).
/// Works in horizontal rails (fixed [width]) and vertical lists (null width).
class ProjectCard extends StatelessWidget {
  final Project project;
  final double? width;
  final double height;
  final VoidCallback? onTap;

  const ProjectCard({
    super.key,
    required this.project,
    this.width,
    this.height = 300,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void open() =>
        onTap != null ? onTap!() : showProjectDetailsSheet(context, project);

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: open,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (project.image != null)
                CachedNetworkImage(
                  // Optimizer bridge: resized + WebP instead of raw S3 PNG.
                  imageUrl: DwelleoImages.optimized(
                    project.image!.displayThumb,
                    width: 1080,
                  ),
                  httpHeaders: DwelleoImages.headers,
                  memCacheWidth: 1080,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) => const _ImageFallback(),
                  errorWidget: (ctx, url, error) => const _ImageFallback(),
                )
              else
                const _ImageFallback(),
              // Bottom scrim so the overlay text stays readable on any photo.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.35, 1.0],
                    colors: [Colors.transparent, Color(0xE6000000)],
                  ),
                ),
              ),
              // The site's tap-affordance arrow.
              PositionedDirectional(
                top: 12,
                end: 12,
                child: ArrowBadge(onTap: open),
              ),
              if (project.isOffPlan)
                PositionedDirectional(
                  top: 12,
                  start: 12,
                  child: Container(
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
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              PositionedDirectional(
                start: 14,
                end: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      project.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (project.cityName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              project.cityName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (project.startingPrice != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.startingFrom,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          SvgPicture.asset(
                            AppSvg.sar,
                            width: 15,
                            height: 15,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Formatters.priceValue(project.startingPrice),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(
        Icons.apartment_rounded,
        size: 44,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
