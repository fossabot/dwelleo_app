import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dwelleo_images.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/html_text.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/project.dart';

/// Quick-look sheet for a project — everything comes from the already
/// loaded [Project] entity (no extra API call). The full project screen
/// lands with the projects branch.
Future<void> showProjectDetailsSheet(BuildContext context, Project project) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _ProjectSheet(project: project),
  );
}

class _ProjectSheet extends StatelessWidget {
  final Project project;

  const _ProjectSheet({required this.project});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (project.image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: DwelleoImages.optimized(
                      project.image!.displayThumb,
                      width: 1080,
                    ),
                    httpHeaders: DwelleoImages.headers,
                    memCacheWidth: 1080,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                if (project.isOffPlan) ...[
                  const SizedBox(width: 8),
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
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (project.cityName != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    project.cityName!,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            if (project.startingPrice != null) ...[
              const SizedBox(height: 12),
              Text(
                l10n.startingFrom,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  SvgPicture.asset(
                    AppSvg.sar,
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(
                      scheme.onSurface,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    Formatters.priceValue(project.startingPrice),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
            if (project.developer != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: project.developer!.image == null
                          ? const Icon(
                              Icons.business_rounded,
                              size: 20,
                              color: AppColors.accent,
                            )
                          : CachedNetworkImage(
                              imageUrl: DwelleoImages.optimized(
                                project.developer!.image!.displayThumb,
                                width: 640,
                              ),
                              httpHeaders: DwelleoImages.headers,
                              memCacheWidth: 160,
                              fit: BoxFit.contain,
                            ),
                    ),
                    const SizedBox(width: 10),
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
                            project.developer!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (project.developer!.isVerified) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.verified_rounded,
                        size: 20,
                        color: AppColors.accentFor(
                          Theme.of(context).brightness,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (project.expectedHandoverDate != null &&
                project.expectedHandoverDate!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${l10n.expectedHandover}: ',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    project.expectedHandoverDate!.split('T').first,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
            if (project.description != null &&
                project.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                // API descriptions arrive as HTML — sanitize for native text.
                HtmlText.strip(project.description!),
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
