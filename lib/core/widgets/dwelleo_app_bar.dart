import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../constants/app_assets.dart';
import '../localization/locale_cubit.dart';
import '../theme/app_colors.dart';
import '../theme/theme_cubit.dart';

/// The single, reusable app bar for the whole app — mirrors the dwelleo.sa
/// header. It always shows:
///   • the brand wordmark (theme-aware), leading;
///   • a language switch that shows the language you can switch TO, with its
///     flag (Saudi flag + العربية while in English; UK flag + English while in
///     Arabic) — so the control communicates the action, like the website;
///   • a sun/moon pill switch for light/dark.
///
/// Screens pass [actions] for extra trailing controls (e.g. a Skip button).
/// The logo + language + theme controls stay identical everywhere, so no screen
/// re-implements its own app bar.
class DwelleoAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Extra trailing controls appended after the language + theme controls.
  final List<Widget> actions;

  /// Transparent bar that lets a full-bleed body (e.g. the onboarding gradient)
  /// show through. Pair with `Scaffold(extendBodyBehindAppBar: true)`.
  final bool transparent;

  const DwelleoAppBar({
    super.key,
    this.actions = const [],
    this.transparent = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.watch<LocaleCubit>().state.languageCode == 'ar';
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: transparent ? Colors.transparent : null,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Image.asset(
        // Logo switches with BOTH language (EN/AR) and theme (light/dark),
        // exactly like the dwelleo.sa header.
        AppImage.wordmark(isArabic: isArabic, isDark: isDark),
        height: 24,
        // Keep the bar usable even if the brand asset is missing.
        errorBuilder: (_, _, _) => Text(
          'DWELLEO',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      actions: [
        const LanguageToggle(),
        const SizedBox(width: 6),
        const ThemeSwitch(),
        ...actions,
        // EdgeInsetsDirectional ensures this gap is always at the screen edge
        // (right in LTR, left in RTL) rather than being position-dependent.
        const Padding(padding: EdgeInsetsDirectional.only(end: 8)),
      ],
    );
  }
}

/// Flag + label of the language the user can switch TO (not the current one),
/// matching the dwelleo.sa header. Tapping flips EN <-> AR (and RTL/LTR).
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleCubit>().state.languageCode == 'ar';
    final targetArabic = !isArabic;
    final flag = targetArabic ? AppImage.flagAr : AppImage.flagEn;
    final label = targetArabic ? 'العربية' : 'English';
    final fg = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () =>
          context.read<LocaleCubit>().setLocale(targetArabic ? 'ar' : 'en'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.asset(
                flag,
                width: 22,
                height: 22,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.language, size: 22, color: fg),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Website-style sun/moon pill switch with a lime thumb. Toggling from
/// ThemeMode.system uses the effective brightness so the first tap always
/// visibly flips the theme.
class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeCubit>().state;
    final platformDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark =
        mode == ThemeMode.dark || (mode == ThemeMode.system && platformDark);
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => context.read<ThemeCubit>().toggle(currentlyDark: isDark),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : const Color(0xFFE7E9E2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outline),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              size: 15,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
