import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/routing/route_paths.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Image.asset(
                  'assets/images/launcher/logo.png',
                  height: 64,
                  errorBuilder: (_, _, _) => const FlutterLogo(size: 64),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Choose your language',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              Text(
                'اختر لغتك',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _LanguageButton(label: 'English', languageCode: 'en'),
              const SizedBox(height: 16),
              _LanguageButton(label: 'العربية', languageCode: 'ar'),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({required this.label, required this.languageCode});

  final String label;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {
        await context.read<LocaleCubit>().setLocale(languageCode);
        if (context.mounted) context.go(RoutePaths.login);
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
