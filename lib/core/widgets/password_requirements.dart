import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../localization/locale_cubit.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';

/// Live password-policy checklist. Each rule starts muted and turns to the theme
/// accent with a filled check the moment the typed [password] satisfies it, so
/// the user sees exactly what they've achieved and what's still required to
/// match the Dwelleo policy (upper + lower + digit, min 8).
class PasswordRequirements extends StatelessWidget {
  final String password;
  const PasswordRequirements(this.password, {super.key});

  @override
  Widget build(BuildContext context) {
    final ar = context.watch<LocaleCubit>().state.languageCode == 'ar';
    final rules = <(bool, String)>[
      (
        Validators.hasMinLength(password),
        ar ? '8 أحرف على الأقل' : 'At least 8 characters',
      ),
      (
        Validators.hasUpper(password),
        ar ? 'حرف كبير واحد (A-Z)' : 'One uppercase letter (A–Z)',
      ),
      (
        Validators.hasLower(password),
        ar ? 'حرف صغير واحد (a-z)' : 'One lowercase letter (a–z)',
      ),
      (
        Validators.hasDigit(password),
        ar ? 'رقم واحد (0-9)' : 'One number (0–9)',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (met, label) in rules)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _Rule(met: met, label: label),
          ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  final bool met;
  final String label;
  const _Rule({required this.met, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = met
        ? AppColors.accentFor(Theme.of(context).brightness)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            key: ValueKey(met),
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: met ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
