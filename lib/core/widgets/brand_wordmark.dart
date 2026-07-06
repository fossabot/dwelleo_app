import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../constants/app_assets.dart';
import '../localization/locale_cubit.dart';

/// Dwelleo wordmark that switches with BOTH language (EN/AR) and theme
/// (light=purple, dark=lime) — exactly like the dwelleo.sa header.
class BrandWordmark extends StatelessWidget {
  final double height;
  const BrandWordmark({super.key, this.height = 26});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      AppImage.wordmark(isArabic: isArabic, isDark: isDark),
      height: height,
    );
  }
}
