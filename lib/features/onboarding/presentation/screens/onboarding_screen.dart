import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_state.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dwelleo_app_bar.dart';

/// First-run value-prop onboarding. Theme-aware (light + dark), animated:
/// a pulsing brand glow and a parallax page transition. Mirrors dwelleo.sa's
/// hero with the in-app-bar language + theme controls and a Skip -> Login.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _controller = PageController();
  late final AnimationController _glow;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _controller.addListener(() {
      setState(
        () => _page = _controller.page ?? _controller.initialPage.toDouble(),
      );
    });
  }

  @override
  void dispose() {
    _glow.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await sl<SecureStorage>().setOnboardingDone();
    sl<SessionState>().onboardingDone = true;
    if (mounted) context.go(RoutePaths.login);
  }

  void _next(int count) {
    if (_page.round() >= count - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ar = context.watch<LocaleCubit>().state.languageCode == 'ar';
    final slides = _slides(ar);
    final isLast = _page.round() == slides.length - 1;

    final gradient = isDark
        ? const [AppColors.heroTop, AppColors.heroBottom]
        : const [Color(0xFFFFFFFF), Color(0xFFEFF2E6)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DwelleoAppBar(
        transparent: true,
        actions: [
          TextButton(onPressed: _finish, child: Text(ar ? 'تخطي' : 'Skip')),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.35),
            radius: 1.15,
            colors: gradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: slides.length,
                  itemBuilder: (_, i) {
                    final delta = (_page - i);
                    final t = (1 - delta.abs()).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(delta * -40, 0),
                        child: Transform.scale(
                          scale: 0.92 + 0.08 * t,
                          child: _Slide(data: slides[i], glow: _glow),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _Dots(count: slides.length, page: _page),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _next(slides.length),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        isLast
                            ? (ar ? 'ابدأ الآن' : 'Get Started')
                            : (ar ? 'التالي' : 'Next'),
                        key: ValueKey(isLast),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  List<_SlideData> _slides(bool ar) => [
    _SlideData(
      isLogo: true,
      title: ar ? 'اعثر على منزل أحلامك' : 'Find Your Dream Home',
      subtitle: ar
          ? 'انضم إلى آلاف المستخدمين الذين يكتشفون العقارات المثالية مع منصة دويليو المدعومة بالذكاء الاصطناعي.'
          : "Join thousands of users discovering the perfect properties with Dwelleo's AI-powered platform.",
    ),
    _SlideData(
      icon: Icons.apartment_rounded,
      title: ar ? 'شراء، إيجار وعلى الخارطة' : 'Buy, Rent & Off-Plan',
      subtitle: ar
          ? 'استكشف عقارات موثقة في جميع أنحاء المملكة — شقق وفلل ومشاريع على الخارطة، في مكان واحد.'
          : 'Explore verified listings across Saudi Arabia — apartments, villas, and off-plan projects, all in one place.',
    ),
    _SlideData(
      icon: Icons.auto_awesome_rounded,
      title: ar
          ? 'بحث و وكيل مبيعات بالذكاء الاصطناعي'
          : 'AI Search & Sales Agent',
      subtitle: ar
          ? 'ابحث بالصوت أو النص واحصل على إجابات فورية بالعربية والإنجليزية، على مدار الساعة.'
          : 'Search by voice or text and get instant, bilingual answers — 24/7.',
    ),
  ];
}

class _Slide extends StatelessWidget {
  final _SlideData data;
  final Animation<double> glow;
  const _Slide({required this.data, required this.glow});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Accent flips by theme (purple in light, lime in dark) — applied to the
    // glow AND the hero mark so the first slide is never a desaturated grey PNG.
    final accent = AppColors.accentFor(theme.brightness);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: glow,
            builder: (context, child) {
              final g = glow.value;
              return Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: 0.10 + 0.22 * g),
                      Colors.transparent,
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Transform.scale(scale: 0.96 + 0.06 * g, child: child),
              );
            },
            // Uniform ~116px hero across all three slides; the logo PNG is
            // tinted to the accent via srcIn so it matches the icon slides.
            child: data.isLogo
                ? Image.asset(
                    AppImage.onboardingDark,
                    width: 116,
                    height: 116,
                    color: accent,
                    colorBlendMode: BlendMode.srcIn,
                  )
                : Icon(data.icon, size: 116, color: accent),
          ),
          const SizedBox(height: 44),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(height: 1.18),
          ),
          const SizedBox(height: 14),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final double page;
  const _Dots({required this.count, required this.page});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final t = (1 - (page - i).abs()).clamp(0.0, 1.0);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8 + 16 * t,
          height: 8,
          decoration: BoxDecoration(
            color: Color.lerp(
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
              AppColors.primary,
              t,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _SlideData {
  final bool isLogo;
  final IconData? icon;
  final String title;
  final String subtitle;
  const _SlideData({
    this.isLogo = false,
    this.icon,
    required this.title,
    required this.subtitle,
  });
}
