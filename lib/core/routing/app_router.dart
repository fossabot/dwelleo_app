import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../di/service_locator.dart';
import '../session/session_state.dart';
import '../../app/app_shell.dart';
import '../../features/ai_sales_agent/presentation/screens/ai_sales_agent_screen.dart';
import '../../features/ai_search/presentation/screens/ai_search_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/signup_form_screen.dart';
import '../../features/auth/presentation/screens/verification_code_screen.dart';
import '../../features/home/presentation/screens/explore_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/language_selection_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/properties/domain/entities/property_query.dart';
import '../../features/properties/presentation/screens/properties_list_screen.dart';
import '../../features/properties/presentation/screens/property_detail_screen.dart';
import '../../features/properties/presentation/screens/saved_properties_screen.dart';
import '../../features/subscriptions/presentation/screens/subscriptions_screen.dart';
import 'route_paths.dart';

class AppRouter {
  AppRouter._();

  // NOTE: a "skip onboarding once completed + auth" redirect guard will be added
  // when the login/signup flow lands. It is intentionally omitted now so the
  // onboarding flow is always reachable while we build and verify it.
  /// Auth routes (reachable only while logged out).
  static const Set<String> _authRoutes = {
    RoutePaths.login,
    RoutePaths.forgotPassword,
    RoutePaths.signupRole,
    RoutePaths.signupForm,
    RoutePaths.signupOtp,
    RoutePaths.language,
  };

  static final GoRouter router = GoRouter(
    initialLocation: RoutePaths.onboarding,
    debugLogDiagnostics: true,
    // Synchronous guard over the in-memory [SessionState] (populated at boot):
    //   not onboarded        → force onboarding
    //   onboarded, logged out → auth routes only (else → login)
    //   logged in            → onboarding/auth routes bounce to home
    redirect: (context, state) {
      final session = sl<SessionState>();
      final loc = state.matchedLocation;
      final atOnboarding = loc == RoutePaths.onboarding;

      if (!session.onboardingDone) {
        return atOnboarding ? null : RoutePaths.onboarding;
      }
      if (!session.isLoggedIn) {
        return _authRoutes.contains(loc) ? null : RoutePaths.login;
      }
      return (atOnboarding || _authRoutes.contains(loc))
          ? RoutePaths.home
          : null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.onboarding,
        name: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.language,
        name: RoutePaths.language,
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.signupRole,
        name: RoutePaths.signupRole,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: RoutePaths.signupForm,
        name: RoutePaths.signupForm,
        builder: (context, state) =>
            SignupFormScreen(role: state.extra as String?),
      ),
      GoRoute(
        path: RoutePaths.signupOtp,
        name: RoutePaths.signupOtp,
        builder: (context, state) =>
            VerificationCodeScreen(email: (state.extra as String?) ?? ''),
      ),
      // ── Main shell: bottom navigation over five parallel branches ─────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: RoutePaths.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Agent-first IA: the AI Sales Agent owns a tab (the app's main
          // feature); Explore (projects) moved to a pushed route below.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.aiSalesAgent,
                name: RoutePaths.aiSalesAgent,
                builder: (context, state) => const AiSalesAgentScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.aiSearch,
                name: RoutePaths.aiSearch,
                builder: (context, state) => const AiSearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.saved,
                name: RoutePaths.saved,
                builder: (context, state) => const SavedPropertiesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                name: RoutePaths.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: RoutePaths.subscriptions,
        name: RoutePaths.subscriptions,
        builder: (context, state) => const SubscriptionsScreen(),
      ),

      // Projects browser — pushed over the shell now that the Sales Agent
      // owns its former tab. Optional pre-selected city via `extra`.
      GoRoute(
        path: RoutePaths.explore,
        name: RoutePaths.explore,
        builder: (context, state) =>
            ExploreScreen(initialCity: state.extra as String?),
      ),

      // Property list/detail push OVER the shell (full-screen, no bottom bar) —
      // they are destinations from Home, not tabs.
      GoRoute(
        path: RoutePaths.propertySearch,
        name: RoutePaths.propertySearch,
        builder: (context, state) {
          // `extra` union: a String pre-localized title (Home quick actions,
          // partner sheets) OR a full PropertyQuery (AI Search hands over its
          // interpreted query so both screens show identical results).
          final extra = state.extra;
          return PropertiesListScreen(
            listingType: state.uri.queryParameters['type'],
            cityId: int.tryParse(state.uri.queryParameters['city'] ?? ''),
            propertyTypeId: int.tryParse(
              state.uri.queryParameters['ptype'] ?? '',
            ),
            developerId: int.tryParse(state.uri.queryParameters['dev'] ?? ''),
            title: extra is String ? extra : null,
            initialQuery: extra is PropertyQuery ? extra : null,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.propertyDetail,
        name: RoutePaths.propertyDetail,
        builder: (context, state) {
          final slug = state.pathParameters['slug'];
          if (slug == null || slug.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Property not found')),
            );
          }
          return PropertyDetailScreen(slug: slug);
        },
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
}
