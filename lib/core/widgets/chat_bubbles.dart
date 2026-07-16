import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared chat bubbles for the AI surfaces (AI Search + AI Sales Agent).
/// Extracted from the AI Search screen once a second feature needed them
/// (CLAUDE.md §A2 — shared code lives in core/).

/// The user's bubble — lime in dark mode, brand purple in light mode
/// (dwelleo.sa parity).
class UserChatBubble extends StatelessWidget {
  final String text;

  const UserChatBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: dark ? AppColors.primary : AppColors.accent,
          borderRadius: const BorderRadiusDirectional.only(
            topStart: Radius.circular(16),
            topEnd: Radius.circular(16),
            bottomStart: Radius.circular(16),
            bottomEnd: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: dark ? AppColors.ink : Colors.white,
          ),
        ),
      ),
    );
  }
}

/// The agent's speech bubble — theme-aware: a dark surface with white text in
/// dark mode, and a light grey surface with dark text in light mode (a pure
/// black bubble in light mode reads as a bug).
class AgentChatBubble extends StatelessWidget {
  final Widget child;

  const AgentChatBubble({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final bubble = dark ? AppColors.cardDark : const Color(0xFFEFF1EA);
    final onBubble = dark ? Colors.white : AppColors.textPrimary;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: bubble,
          borderRadius: const BorderRadiusDirectional.only(
            topStart: Radius.circular(4),
            topEnd: Radius.circular(16),
            bottomStart: Radius.circular(16),
            bottomEnd: Radius.circular(16),
          ),
          border: Border.all(color: scheme.outline),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 13.5,
            height: 1.45,
            fontWeight: FontWeight.w500,
            color: onBubble,
          ),
          child: child,
        ),
      ),
    );
  }
}
