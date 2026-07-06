import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/di/service_locator.dart';
import '../core/localization/locale_cubit.dart';
import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_cubit.dart';
import '../l10n/app_localizations.dart';

class DwelleoApp extends StatelessWidget {
  const DwelleoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<LocaleCubit>()),
        BlocProvider.value(value: sl<ThemeCubit>()),
      ],
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) {
          final themeMode = context.watch<ThemeCubit>().state;
          return MaterialApp.router(
            title: 'Dwelleo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            locale: locale,
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
