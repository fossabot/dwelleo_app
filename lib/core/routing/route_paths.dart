/// Routes registered in [AppRouter]. Add a constant here only when its
/// GoRoute exists — keep this list in sync with the router so every path
/// resolves.
abstract final class RoutePaths {
  /// First-run value-prop onboarding (entry point).
  static const String onboarding = '/';

  /// Optional standalone language picker (the in-app-bar toggle is primary).
  static const String language = '/language';

  /// Login (Welcome Back).
  static const String login = '/login';

  /// Forgot-password wizard (email → code → new password).
  static const String forgotPassword = '/forgot-password';

  /// Account-type selection — part of the SIGN-UP flow, not onboarding.
  static const String signupRole = '/signup/role';

  /// Sign-up step 2 — personal info form (carries the chosen role as `extra`).
  static const String signupForm = '/signup/form';

  /// Sign-up step 3 — OTP verification (carries the email as `extra`).
  static const String signupOtp = '/signup/verify';

  // ── Main shell (bottom navigation) ────────────────────────────────────────
  /// Post-auth landing — the Home tab of the shell.
  static const String home = '/home';

  /// Projects browser tab.
  static const String explore = '/explore';

  /// AI search tab (center action).
  static const String aiSearch = '/ai-search';

  /// Saved/favorite properties tab.
  static const String saved = '/saved';

  /// Account tab.
  static const String profile = '/profile';

  /// Subscription plans (nav strip → Subscriptions; API list is live but
  /// currently empty, see REAL_API_SPEC §5).
  static const String subscriptions = '/subscriptions';

  /// AI Sales Agent — its own surface, DISTINCT from AI Search (review P0:
  /// dwelleo.sa positions them as separate products).
  static const String aiSalesAgent = '/ai-sales-agent';

  static const String propertySearch = '/properties';
  static const String propertyDetail = '/properties/:slug';

  static String propertyDetailPath(String slug) => '/properties/$slug';

  /// Properties list, optionally filtered by listing type
  /// (`for-sale` / `for-rent`), city, property type and developer — the ids
  /// the real API's Spatie filters expect. Null listing type = curated set.
  static String propertySearchPath(
    String? listingType, {
    int? cityId,
    int? propertyTypeId,
    int? developerId,
  }) {
    final params = <String, String>{
      'type': ?listingType,
      'city': ?cityId?.toString(),
      'ptype': ?propertyTypeId?.toString(),
      'dev': ?developerId?.toString(),
    };
    return Uri(
      path: propertySearch,
      queryParameters: params.isEmpty ? null : params,
    ).toString();
  }

  // ── Full-page routes from the properties/projects refactor ──
  /// Project detail — VERIFIED GET /projects/{id}.
  static const String projectDetail = '/projects/:id';
  static String projectDetailPath(int id) => '/projects/$id';

  /// Developer/broker profile (list-payload preview via `extra`).
  static const String developerProfile = '/developers/:id';
  static String developerProfilePath(int id) => '/developers/$id';

  /// Developers & brokers directory with search.
  static const String developersDirectory = '/developers';

  /// Side-by-side compare of the two tray properties.
  static const String compare = '/compare';

  /// Full-page Price Statistics (live /market/cities table).
  static const String priceStats = '/market/price-stats';

  /// 6-phase Estimate Property wizard.
  static const String estimate = '/estimate';

  /// Market Insights — the site's data-driven charts page.
  static const String marketInsights = '/market-insights';
}
