import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auth_background.dart';
import '../../../../core/widgets/dwelleo_app_bar.dart';

/// Account-type selection — step 1 of SIGN-UP (mirrors dwelleo.sa /register
/// "Join Dwelleo · I am a…"). Pick one role; Continue carries it to step 2.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedKey;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleCubit>().state.languageCode == 'ar';
    final roles = _roles(isArabic);

    return Scaffold(
      appBar: const DwelleoAppBar(),
      body: AuthBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'انضم إلى دويليو' : 'Join Dwelleo',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic
                      ? 'اختر نوع حسابك للبدء'
                      : 'Choose your account type to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    itemCount: roles.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.92,
                        ),
                    itemBuilder: (_, i) => _RoleCard(
                      data: roles[i],
                      selected: roles[i].key == _selectedKey,
                      onTap: () => setState(() => _selectedKey = roles[i].key),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Continue is disabled (grey) until a role is selected.
                FilledButton(
                  onPressed: _selectedKey == null
                      ? null
                      : () => context.go(
                          RoutePaths.signupForm,
                          extra: _selectedKey,
                        ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isArabic ? 'متابعة' : 'Continue'),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_RoleData> _roles(bool ar) => [
    _RoleData(
      'buyer',
      AppSvg.roleBuyer,
      ar ? 'مشتري / مستأجر' : 'Buyer / Renter',
      ar
          ? 'ابحث عن عقارك المثالي وقم بشرائه'
          : 'Find and purchase your dream property',
    ),
    _RoleData(
      'seller',
      AppSvg.roleSeller,
      ar ? 'بائع / مؤجر' : 'Seller / Rental',
      ar
          ? 'أدرج وبع عقاراتك للمشترين'
          : 'List and sell your properties to buyers',
    ),
    _RoleData(
      'agent',
      AppSvg.roleAgent,
      ar ? 'وكيل' : 'Agent',
      ar ? 'وكيل عقاري يساعد العملاء' : 'Agent helping clients buy and sell',
    ),
    _RoleData(
      'broker',
      AppSvg.roleBroker,
      ar ? 'وسيط' : 'Broker',
      ar
          ? 'وسيط مرخّص يدير المعاملات'
          : 'Licensed broker managing transactions',
    ),
    _RoleData(
      'developer',
      AppSvg.roleDeveloper,
      ar ? 'مطوّر' : 'Developer',
      ar ? 'طوّر واعرض مشاريعك العقارية' : 'Develop and showcase your projects',
    ),
    _RoleData(
      'individual_broker',
      AppSvg.roleIndividualBroker,
      ar ? 'وسيط فردي' : 'Individual Broker',
      ar ? 'اعرض عقاراتك بشكل فردي' : 'Showcase your real estate individually',
    ),
  ];
}

class _RoleCard extends StatelessWidget {
  final _RoleData data;
  final bool selected;
  final VoidCallback onTap;
  const _RoleCard({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Accent flips by theme (purple in light, lime in dark), like the site.
    final accent = AppColors.accentFor(
      isDark ? Brightness.dark : Brightness.light,
    );
    final cardColor = isDark
        ? AppColors.surfaceDark
        : scheme.surfaceContainerHighest;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? accent : scheme.outline,
          width: selected ? 2 : 1,
        ),
        // Soft, diffuse glow when selected (no tight/sharp halo): larger blur,
        // slightly negative spread so it feathers out instead of ringing.
        boxShadow: selected
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.16),
                  blurRadius: 28,
                  spreadRadius: -4,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SvgPicture.asset(
                  data.svg,
                  width: 26,
                  height: 26,
                  colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                ),
              ),
              const Spacer(),
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleData {
  final String key;
  final String svg;
  final String title;
  final String subtitle;
  const _RoleData(this.key, this.svg, this.title, this.subtitle);
}
